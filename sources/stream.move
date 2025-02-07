
// Copyright 2022  Authors. Licensed under Apache-2.0 License.
module moveflow::stream {

    use std::type_name;
    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::event::emit;
    use std::vector;

    const MIN_DEPOSIT_BALANCE: u64 = 10000; // 0.0001 APT(decimals=8)
    const MIN_RATE_PER_INTERVAL: u64 = 1000; // 0.00000001 APT(decimals=8)
    const INIT_FEE_POINT: u8 = 25; // 0.25%

    const ERR_STREAM_INSUFFICIENT_BALANCES: u64 = 10001;
    const ERR_STREAM_BALANCE_TOO_LITTLE: u64 = 10002;
    const ERR_STREAM_NOT_MISMATCH: u64 = 10003;
    const ERR_STREAM_NOT_START: u64 = 10004;
    const ERR_STREAM_EXCEED_STOP_TIME: u64 = 10005;
    const ERR_STREAM_IS_CLOSE: u64 = 10006;
    const ERR_STREAM_RATE_TOO_LITTLE: u64 = 10007;
    const ERR_COIN_CONF_NOT_FOUND: u64 = 10008;
    const ERR_COIN_CONF_IS_EXSIT: u64 = 10009;
    const ERR_STREAM_STOP_TIME: u64 = 10010;
    const ERR_STREAM_REJECT_EXTEND: u64 = 10011;
    const ERR_STREAM_REJECT_CLOSE: u64 = 10012;
    const ERR_STREAM_REJECT_PAUSE: u64 = 10013;
    const ERR_STREAM_PAUSE_STATUS: u64 = 10014;
    const ERR_STREAM_NO_PAUSE_STATUS: u64 = 10015;
    const ERR_STREAM_NO_WITHDRAW_AMOUNT: u64 = 10016;
    const ERR_STREAM_NO_PERMISSION: u64 = 10017;

    const EVENT_TYPE_CREATE: u8 = 0;
    const EVENT_TYPE_WITHDRAW: u8 = 1;
    const EVENT_TYPE_CLOSE: u8 = 2;
    const EVENT_TYPE_EXTEND: u8 = 3;
    const EVENT_TYPE_REGISTER_COIN: u8 = 4;
    const EVENT_TYPE_MODIFY_FEE_POINT: u8 = 5;
    const EVENT_TYPE_MODIFY_FEE_RECIPIENT: u8 = 6;
    const EVENT_TYPE_MODIFY_RECIPIENT: u8 = 7;
    const EVENT_TYPE_PAUSE: u8 = 8;
    const EVENT_TYPE_RESUME: u8 = 9;

    const SALT: vector<u8> = b"Stream::streampay";

    /// Event emitted when created/withdraw/closed/extend a streampay
    struct StreamEvent has copy, drop {
        id: ID,
        event_type: u8,
        sender: address,
        recipient: address,
        deposit_amount: u64,
        remaining_amount: u64,
        extend_amount: u64,
        withdraw_amount: u64,
    }

    /// Event emitted when pause/resume a streampay
    struct PauseEvent has copy, drop {
        id: ID,
        event_type: u8,
        paused: bool,
        pause_at: u64,
    }

    /// Event emitted when register/update fee point
    struct ConfigEvent has copy, drop {
        event_type: u8,
        coin_type: String,
        fee_point: u8,
        fee_recipient: address,
    }

    struct StreamInfo<phantom CoinType> has key {
        id: UID,
        name: String,
        remark: String,
        sender: address,
        recipient: address,
        interval: u64,
        rate_per_interval: u64,
        start_time: u64,
        stop_time: u64,
        last_withdraw_time: u64,
        create_at: u64,
        deposit_amount: u64, // no update
        withdrawn_amount: u64,
        remaining_amount: u64, // update when withdraw
        closed: bool,
        feature_info: FeatureInfo,
        fee_info: FeeInfo,
        pause_info: PauseInfo,
        balance: Balance<CoinType>,
    }

    struct FeatureInfo has copy, drop, store {
        pauseable: bool,
        sender_closeable: bool,
        recipient_modifiable: bool,
    }

    struct FeeInfo has copy, drop, store {
        fee_recipient: address,
        fee_point: u8,
    }

    struct PauseInfo has copy, drop, store {
        paused: bool,
        pause_at: u64,
        acc_paused_time: u64,
    }

    struct GlobalConfig has key {
        id: UID,
        fee_recipient: address,
        coin_configs: Table<String, CoinConfig>,
        incoming_stream: Table<address, vector<ID>>,
        outgoing_stream: Table<address, vector<ID>>,
    }

    struct CoinConfig has copy, drop, store {
        fee_point: u8,
        coin_type: String,
    }

    struct ManageCap has key, store {
        id: UID,
    }

    struct SenderCap has key, store {
        id: UID,
        stream: ID,
    }

    struct RecipientCap has key, store {
        id: UID,
        stream: ID,
    }

    /// set fee_recipient and admin
    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let global = GlobalConfig{
            id: object::new(ctx),
            fee_recipient: sender,
            coin_configs: table::new<String, CoinConfig>(ctx),
            incoming_stream: table::new<address, vector<ID>>(ctx),
            outgoing_stream: table::new<address, vector<ID>>(ctx),
        };

        let manage_cap = ManageCap{
            id: object::new(ctx),
        };

        register_coin<0x2::sui::SUI>(&manage_cap, &mut global, INIT_FEE_POINT, ctx);

        transfer::share_object(global);
        transfer::public_transfer(manage_cap, sender);
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let global = GlobalConfig{
            id: object::new(ctx),
            fee_recipient: sender,
            coin_configs: table::new<String, CoinConfig>(ctx),
            incoming_stream: table::new<address, vector<ID>>(ctx),
            outgoing_stream: table::new<address, vector<ID>>(ctx),
        };

        let manage_cap = ManageCap{
            id: object::new(ctx),
        };

        register_coin<0x2::sui::SUI>(&manage_cap, &mut global, INIT_FEE_POINT, ctx);

        transfer::share_object(global);
        transfer::public_transfer(manage_cap, sender);
    }

    /// create a stream
    public entry fun create<CoinType>(
        global_config: &mut GlobalConfig,
        payment: Coin<CoinType>,
        name: String,
        remark: String,
        recipient: address,
        deposit_amount: u64, // ex: 100,0000
        start_time: u64,
        stop_time: u64,
        interval: u64,
        closeable: bool,   //default: true
        modifiable: bool,  //default: true
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let stream_id = object::uid_to_inner(&id);
        let current_time = clock::timestamp_ms(clock)/1000;

        // 2. check args
        assert!(stop_time >= start_time && stop_time >= current_time, ERR_STREAM_STOP_TIME);
        assert!(deposit_amount >= MIN_DEPOSIT_BALANCE, ERR_STREAM_BALANCE_TOO_LITTLE);
        check_coin_type<CoinType>(global_config);

        // 3. creat stream
        let duration = (stop_time - start_time) / interval;
        let rate_per_interval: u64 = deposit_amount * 1000 / duration;
        assert!(rate_per_interval >= MIN_RATE_PER_INTERVAL, ERR_STREAM_RATE_TOO_LITTLE);

        let feature_info = FeatureInfo{
            pauseable: closeable,
            sender_closeable: closeable,
            recipient_modifiable: modifiable,
        };

        let fee_info = FeeInfo{
            fee_recipient: global_config.fee_recipient,
            fee_point: fee_point<CoinType>(global_config),
        };

        let pauseInfo = PauseInfo{
            paused: false,
            pause_at: 0u64,
            acc_paused_time: 0u64,
        };

        let stream = StreamInfo {
            id,
            name,
            remark,
            sender,
            recipient,
            interval,
            rate_per_interval,
            start_time,
            stop_time,
            last_withdraw_time: start_time,
            create_at: current_time,
            deposit_amount,
            withdrawn_amount: 0u64,
            remaining_amount: deposit_amount,
            closed: false,
            feature_info,
            fee_info,
            pause_info: pauseInfo,
            balance: balance::zero<CoinType>(),
        };

        // 4. handle assets to escrow
        let paid = handle_payments(&mut stream, payment, deposit_amount);
        transfer::public_transfer(paid, sender);

        // 5. transfer object
        transfer::share_object(stream);

        transfer::public_transfer(SenderCap{
            id: object::new(ctx),
            stream: stream_id,
        }, sender);

        transfer::public_transfer(RecipientCap{
            id: object::new(ctx),
            stream: stream_id,
        }, recipient);

        // 6. add outgoing stream for sender, imcoming stream to recipient

        add_stream_index(&mut global_config.outgoing_stream, sender, stream_id);

        add_stream_index(&mut global_config.incoming_stream, recipient, stream_id);

        // 7. emit create event TO DO
        emit(StreamEvent {
            id: stream_id,
            event_type: EVENT_TYPE_CREATE,
            sender,
            recipient,
            deposit_amount,
            remaining_amount: deposit_amount,
            extend_amount: 0u64,
            withdraw_amount: 0u64,
        });
    }

    public entry fun extend<CoinType>(
        sender_cap: &SenderCap,
        stream: &mut StreamInfo<CoinType>,
        payment: Coin<CoinType>,
        new_stop_time: u64,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let stream_id = object::uid_to_inner(&stream.id);
        let sender = tx_context::sender(ctx);

        // 2. check args
        assert!(sender_cap.stream == object::uid_to_inner(&stream.id), ERR_STREAM_NOT_MISMATCH);
        assert!(!stream.closed, ERR_STREAM_IS_CLOSE);
        assert!(!stream.pause_info.paused, ERR_STREAM_PAUSE_STATUS);
        assert!(new_stop_time > stream.stop_time, ERR_STREAM_STOP_TIME);

        // 3. handle assets to escrow
        let duration = (new_stop_time - stream.stop_time) / stream.interval;
        let deposit_amount = duration * stream.rate_per_interval / 1000;

        let paid = handle_payments(stream, payment, deposit_amount);
        transfer::public_transfer(paid, sender);

        // 4. update stream stats
        stream.stop_time = new_stop_time;
        stream.remaining_amount = stream.remaining_amount + deposit_amount;
        stream.deposit_amount = stream.deposit_amount + deposit_amount;

        // 5. emit open event
        emit(StreamEvent {
            id: stream_id,
            event_type: EVENT_TYPE_EXTEND,
            sender: stream.sender,
            recipient: stream.recipient,
            deposit_amount: stream.deposit_amount,
            remaining_amount: stream.remaining_amount,
            extend_amount: deposit_amount,
            withdraw_amount: 0u64,
        });
    }

    public entry fun close<CoinType>(
        sender_cap: &SenderCap,
        stream: &mut StreamInfo<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. check args
        assert!(sender_cap.stream == object::uid_to_inner(&stream.id), ERR_STREAM_NOT_MISMATCH);

        // 2. excute close
        close_(stream, clock, ctx);
    }

    fun close_<CoinType>(
        stream: &mut StreamInfo<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock)/1000;

        // 2. check args
        assert!(closeable(stream, sender), ERR_STREAM_REJECT_CLOSE);
        assert!(!stream.closed, ERR_STREAM_IS_CLOSE);
        assert!(!stream.pause_info.paused, ERR_STREAM_PAUSE_STATUS);
        // assert!(current_time < stream.stop_time, ERR_STREAM_EXCEED_STOP_TIME);

        // 3. withdraw
        if (current_time > stream.last_withdraw_time + stream.interval){
            withdraw_<CoinType>(stream, clock, ctx);
        };

        // 4. handle assets
        let amount = balance::value( & stream.balance);
        transfer::public_transfer(coin::take( &mut stream.balance, amount, ctx), stream.sender);

        // 5. update stream stats
        stream.remaining_amount = 0;
        stream.closed = true;

        // 6. emit open event
        emit(StreamEvent {
            id: object::uid_to_inner(&stream.id),
            event_type: EVENT_TYPE_CLOSE,
            sender: stream.sender,
            recipient: stream.recipient,
            deposit_amount: stream.deposit_amount,
            remaining_amount: stream.remaining_amount,
            extend_amount: 0u64,
            withdraw_amount: amount,
        });
    }

    public entry fun withdraw<CoinType>(
        stream: &mut StreamInfo<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let current_time = clock::timestamp_ms(clock)/1000;

        // 2. check args
        assert!(current_time > stream.start_time, ERR_STREAM_NOT_START);
        assert!(!stream.pause_info.paused, ERR_STREAM_PAUSE_STATUS);
        assert!(!stream.closed, ERR_STREAM_IS_CLOSE);
        assert!(stream.remaining_amount > 0, ERR_STREAM_INSUFFICIENT_BALANCES);

        let delta = delta_of(current_time, stream);
        assert!(delta > 0, ERR_STREAM_NO_WITHDRAW_AMOUNT);

        withdraw_(stream, clock, ctx);
    }

    fun withdraw_<CoinType>(
        stream: &mut StreamInfo<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let current_time = clock::timestamp_ms(clock)/1000;
        let withdraw_amount = stream.remaining_amount;
        let withdraw_time = stream.stop_time;


        // 2. calc withdraw amount
        // if(stream.pauseInfo.paused){
        //     let delta = delta_of(stream.pauseInfo.pause_at, stream);
        //     assert!(delta > 0, ERR_STREAM_PAUSE_STATUS);
        //     withdraw_amount = stream.rate_per_interval * delta / 1000;
        //     withdraw_time = stream.last_withdraw_time + delta * stream.interval;
        // } else if (current_time < stream.stop_time) {
        let delta = delta_of(current_time, stream);
        if (delta == 0) {
            return
        };
        if (current_time < stream.stop_time) {
            withdraw_amount = stream.rate_per_interval * delta / 1000;
            withdraw_time = stream.last_withdraw_time + delta * stream.interval + stream.pause_info.acc_paused_time;
        };

        assert!(
            withdraw_amount <= stream.remaining_amount && withdraw_amount <= balance::value(&stream.balance),
            ERR_STREAM_INSUFFICIENT_BALANCES,
        );

        // 3. handle assets
        // 2.5 % ---> fee = 250, 2500, 25000, to_escrow = 100,0000 - 2,5000 --> 97,5000
        let (fee_num, to_recipient) = calculate_fee(withdraw_amount, stream.fee_info.fee_point);
        // fee
        transfer::public_transfer(coin::take( &mut stream.balance, fee_num, ctx), stream.fee_info.fee_recipient);
        //withdraw amount
        transfer::public_transfer(coin::take( &mut stream.balance, to_recipient, ctx), stream.recipient);

        // 4. update stream stats
        stream.withdrawn_amount = stream.withdrawn_amount + withdraw_amount;
        stream.remaining_amount = stream.remaining_amount - withdraw_amount;
        stream.last_withdraw_time = withdraw_time;
        stream.pause_info.acc_paused_time = 0;

        // 5. emit open event
        emit(StreamEvent {
            id: object::uid_to_inner(&stream.id),
            event_type: EVENT_TYPE_WITHDRAW,
            sender: stream.sender,
            recipient: stream.recipient,
            deposit_amount: stream.deposit_amount,
            remaining_amount: stream.remaining_amount,
            extend_amount: 0u64,
            withdraw_amount,
        });
    }

    public entry fun pause<CoinType>(
        sender_cap: &SenderCap,
        stream: &mut StreamInfo<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock)/1000;

        // 2. check args
        assert!(sender_cap.stream == object::uid_to_inner(&stream.id), ERR_STREAM_NOT_MISMATCH);
        assert!(current_time < stream.stop_time, ERR_STREAM_STOP_TIME);
        assert!(pauseable(stream, sender), ERR_STREAM_REJECT_PAUSE);
        assert!(!stream.pause_info.paused, ERR_STREAM_PAUSE_STATUS);
        assert!(!stream.closed, ERR_STREAM_IS_CLOSE);

        // 3. withdraw
        if (current_time > stream.last_withdraw_time + stream.interval){
            withdraw_<CoinType>(stream, clock, ctx);
        };

        // 4. modify pause info
        stream.pause_info.paused = true;
        stream.pause_info.pause_at = current_time;

        // 4. emit open event
        emit(PauseEvent {
            id: object::uid_to_inner(&stream.id),
            event_type: EVENT_TYPE_PAUSE,
            paused: true,
            pause_at: current_time,
        });
    }

    public entry fun resume<CoinType>(
        sender_cap: &SenderCap,
        stream: &mut StreamInfo<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. init args
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock)/1000;

        // 2. check args
        assert!(sender_cap.stream == object::uid_to_inner(&stream.id), ERR_STREAM_NOT_MISMATCH);
        assert!(pauseable(stream, sender), ERR_STREAM_REJECT_PAUSE);
        assert!(stream.pause_info.paused, ERR_STREAM_NO_PAUSE_STATUS);
        assert!(!stream.closed, ERR_STREAM_IS_CLOSE);

        // 3. modify pause info
        if (current_time > stream.start_time){
            let paused_time;
            if (stream.pause_info.pause_at < stream.start_time) {
                paused_time = current_time - stream.start_time
            }else{
                paused_time = current_time - stream.pause_info.pause_at;
            };

            stream.pause_info.acc_paused_time = stream.pause_info.acc_paused_time + paused_time;
            stream.stop_time = stream.stop_time + paused_time;
        };

        stream.pause_info.paused = false;
        stream.pause_info.pause_at = 0u64;

        // 4. emit open event
        emit(PauseEvent {
            id: object::uid_to_inner(&stream.id),
            event_type: EVENT_TYPE_RESUME,
            paused: false,
            pause_at: 0u64,
        });
    }

    /// call by  owner
    /// register a coin type for streampay and initialize it
    public entry fun register_coin<CoinType>(
        _: &ManageCap,
        global_config: &mut GlobalConfig,
        fee_point: u8,
        _: &mut TxContext
    ) {
        // 1. init args
        let coin_type = string::from_ascii(type_name::into_string(type_name::get<CoinType>()));

        // 2. check args
        assert!(!table::contains(&global_config.coin_configs, coin_type), ERR_COIN_CONF_IS_EXSIT);

        // 3. create coin config
        let new_coin_config = CoinConfig {
            fee_point,
            coin_type,
        };

        table::add(&mut global_config.coin_configs, coin_type, new_coin_config);

        // 4. emit open event
        emit(ConfigEvent {
            event_type: EVENT_TYPE_REGISTER_COIN,
            coin_type,
            fee_point,
            fee_recipient: global_config.fee_recipient,
        });
    }

    /// set new fee point
    public entry fun set_fee_point<CoinType>(
        _: &ManageCap,
        global_config: &mut GlobalConfig,
        new_fee_point: u8,
        _: &mut TxContext
    ) {
        let coin_config = coin_config<CoinType>(global_config);

        coin_config.fee_point = new_fee_point;

        emit(ConfigEvent {
            event_type: EVENT_TYPE_MODIFY_FEE_POINT,
            coin_type: coin_config.coin_type,
            fee_point: coin_config.fee_point,
            fee_recipient: global_config.fee_recipient,
        });
    }

    /// set new fee point
    public entry fun set_fee_recipient(
        _: &ManageCap,
        global_config: &mut GlobalConfig,
        new_fee_recipient: address,
        _: &mut TxContext
    ) {
        global_config.fee_recipient = new_fee_recipient;

        emit(ConfigEvent {
            event_type: EVENT_TYPE_MODIFY_FEE_RECIPIENT,
            coin_type: string::utf8(b""),
            fee_point: 0u8,
            fee_recipient: global_config.fee_recipient,
        });
    }

    /// set new recipient
    public entry fun set_new_recipient<CoinType>(
        stream: &mut StreamInfo<CoinType>,
        global_config: &mut GlobalConfig,
        new_recipient: address,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let stream_id = object::uid_to_inner(&stream.id);
        assert!(stream.recipient == sender, ERR_STREAM_NO_PERMISSION);
        stream.recipient = new_recipient;

        del_stream_index(&mut global_config.incoming_stream, sender, stream_id);
        add_stream_index(&mut global_config.incoming_stream, new_recipient, stream_id);
    }

    ///intenal function
    fun calculate_fee(
        withdraw_amount: u64,
        fee_point: u8,
    ): (u64, u64) {
        let fee = withdraw_amount * (fee_point as u64) / 10000;

        // never overflow
        (fee, withdraw_amount - fee)
    }

    fun delta_of<CoinType>(withdraw_time: u64, stream: &StreamInfo<CoinType>) : u64 {
        if(withdraw_time < stream.last_withdraw_time + stream.pause_info.acc_paused_time){
            return 0u64
        };

        (withdraw_time - stream.last_withdraw_time - stream.pause_info.acc_paused_time) / stream.interval
    }

    public fun closeable<CoinType>(stream: &StreamInfo<CoinType>, sender: address): bool {
        stream.sender == sender && stream.feature_info.sender_closeable
    }

    public fun pauseable<CoinType>(stream: &StreamInfo<CoinType>, sender: address): bool {
        stream.sender == sender && stream.feature_info.pauseable
    }

    public fun recipient_modifiable<CoinType>(stream: &StreamInfo<CoinType>, sender: address): bool {
        stream.recipient == sender && stream.feature_info.recipient_modifiable
    }

    fun add_stream_index(stream_table: &mut Table<address, vector<ID>>, address: address, stream_id: ID ) {
        if (!table::contains(stream_table, address)){
            table::add(
                stream_table,
                address,
                vector::empty<ID>(),
            )
        };

        let streams = table::borrow_mut(stream_table, address);

        vector::push_back(streams, stream_id);
    }

    fun del_stream_index(stream_table: &mut Table<address, vector<ID>>, address: address, stream_id: ID ) {
        if (table::contains(stream_table, address)){
            let sender_stream = table::borrow_mut(stream_table, address);
            let i = 0;
            while (i < vector::length(sender_stream)){
                if (*vector::borrow(sender_stream, i) == stream_id){
                    break
                };
                i = i + 1;
            };
            vector::remove(sender_stream, i);
        };
    }

    fun handle_payments<CoinType>(
        stream: &mut StreamInfo<CoinType>,
        payment: Coin<CoinType>,
        deposit_amount: u64,
    ): Coin<CoinType> {
        // let paid = vector::pop_back(&mut payments);
        // pay::join_vec(&mut paid, payments);
        assert!(coin::value(&payment) >= deposit_amount, ERR_STREAM_INSUFFICIENT_BALANCES);

        let price = balance::split(coin::balance_mut<CoinType>(&mut payment), deposit_amount);
        balance::join( &mut stream.balance, price);
        payment
    }

    fun coin_config<CoinType>(global_config: &mut GlobalConfig): &mut CoinConfig {
        let coin_type = check_coin_type<CoinType>(global_config);
        table::borrow_mut(&mut global_config.coin_configs, coin_type)
    }

    fun check_coin_type<CoinType>(global_config: &GlobalConfig): String {
        let coin_type = string::from_ascii(type_name::into_string(type_name::get<CoinType>()));
        assert!(table::contains(&global_config.coin_configs, coin_type), ERR_COIN_CONF_NOT_FOUND);
        coin_type
    }

    public fun fee_point<CoinType>(global_config: &mut GlobalConfig): u8 {
        let coin_config = coin_config<CoinType>(global_config);
        coin_config.fee_point
    }

    public fun fee_recipient(global_config: &GlobalConfig): address {
        global_config.fee_recipient
    }

    public fun coin_type_exist<CoinType>(global_config: &GlobalConfig): bool {
        let coin_type = string::from_ascii(type_name::into_string(type_name::get<CoinType>()));
        table::contains(&global_config.coin_configs, coin_type)
    }

    public fun get_deposite_amount<CoinType>(stream: &StreamInfo<CoinType>): u64{
        stream.deposit_amount
    }

    public fun get_withdrawn_amount<CoinType>(stream: &StreamInfo<CoinType>): u64{
        stream.withdrawn_amount
    }

    public fun get_remaining_amount<CoinType>(stream: &StreamInfo<CoinType>): u64{
        balance::value(&stream.balance)
    }
}

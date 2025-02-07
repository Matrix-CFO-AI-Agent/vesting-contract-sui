#[test_only]
module moveflow::stream_tests {

    use std::option;

    use sui::test_scenario::{Self};
    use sui::coin::{Self, from_balance, mint_balance, Coin};
    use sui::clock::{Self};
    use sui::url;
    use sui::transfer;
    use sui::object;

    use moveflow::stream::{Self, ManageCap, GlobalConfig, SenderCap, StreamInfo};
    use std::string;

    struct STREAM_TESTS has drop {}

    const OWNER: address = @0xA1C05;
    const SENDER: address = @0xA1C01;
    const RECIPIENT: address = @0xA1C04;

    #[test]
    fun create_global(){
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        //init module
        let ctx = test_scenario::ctx(scenario);
        stream::init_test(ctx);

        test_scenario::next_tx(scenario, OWNER); {
            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            assert!(stream::fee_recipient(&mut global) == OWNER, 0);

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        test_scenario::next_tx(scenario, OWNER); {
            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let ctx = test_scenario::ctx(scenario);
            stream::set_fee_recipient(&manCap, &mut global, SENDER, ctx);
            assert!(stream::fee_recipient(&mut global) == SENDER, 0);

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        test_scenario::next_tx(scenario, OWNER); {

            let ctx = test_scenario::ctx(scenario);
            let witness = STREAM_TESTS{};
            let (treasury, metadata) = coin::create_currency(
                witness,
                6,
                b"COIN_TESTS",
                b"coin_name",
                b"description",
                option::some(url::new_unsafe_from_bytes(b"icon_url")), ctx
            );
            transfer::public_freeze_object(metadata);
            transfer::public_transfer(treasury, OWNER);

            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let ctx = test_scenario::ctx(scenario);
            stream::register_coin<STREAM_TESTS>(&manCap, &mut global, 100, ctx);
            assert!(stream::fee_point<STREAM_TESTS>(&mut global) == 100, 0);

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        test_scenario::next_tx(scenario, OWNER); {

            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let ctx = test_scenario::ctx(scenario);
            stream::set_fee_point<STREAM_TESTS>(&manCap, &mut global, 250, ctx);
            assert!(stream::fee_point<STREAM_TESTS>(&mut global) == 250, 0);

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
            test_scenario::return_shared<GlobalConfig>(global);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun create_stream(){

        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        //init module
        let ctx = test_scenario::ctx(scenario);
        stream::init_test(ctx);
        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);
        let ctx = test_scenario::ctx(scenario);
        let witness = STREAM_TESTS{};
        let (treasury, metadata) = coin::create_currency(
            witness,
            6,
            b"COIN_TESTS",
            b"coin_name",
            b"description",
            option::some(url::new_unsafe_from_bytes(b"icon_url")),
            ctx,
        );
        // let coin1 = from_balance(
        //     mint_balance<STREAM_TESTS>(&mut treasury, 10000),
        //     test_scenario::ctx(scenario)
        // );
        let coin2 = from_balance(
            mint_balance<STREAM_TESTS>(&mut treasury, 100000),
            test_scenario::ctx(scenario)
        );
        // let coin3 = from_balance(
        //     mint_balance<STREAM_TESTS>(&mut treasury, 20000),
        //     test_scenario::ctx(scenario)
        // );
        let coin4 = from_balance(
            mint_balance<STREAM_TESTS>(&mut treasury, 100000),
            test_scenario::ctx(scenario)
        );
        let coin5 = from_balance(
            mint_balance<STREAM_TESTS>(&mut treasury, 500000),
            test_scenario::ctx(scenario)
        );
        // let coin1_id = object::id(&coin1);
        let coin2_id = object::id(&coin2);
        // let coin3_id = object::id(&coin3);
        let coin4_id = object::id(&coin4);
        // let coin5_id = object::id(&coin5);
        // transfer::public_transfer(coin1, SENDER);
        transfer::public_transfer(coin2, SENDER);
        // transfer::public_transfer(coin3, SENDER);
        transfer::public_transfer(coin4, SENDER);
        transfer::public_transfer(coin5, SENDER);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, OWNER);

        test_scenario::next_tx(scenario, OWNER); {
            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            stream::register_coin<STREAM_TESTS>(&manCap, &mut global, 100, ctx);

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        test_scenario::next_tx(scenario, SENDER); {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            // let clock = test_scenario::take_shared<Clock>(scenario);
            let current = clock::timestamp_ms(&clock)/1000;

            // let coin1 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin1_id);
            let coin2 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin2_id);

            // let payments = vector::empty<Coin<STREAM_TESTS>>();
            // vector::push_back(&mut payments, coin1);
            // vector::push_back(&mut payments, coin2);
            stream::create<STREAM_TESTS>(
                &mut global,
                coin2,
                string::utf8( b"test1"),
                string::utf8( b"test1"),
                RECIPIENT,
                80000,
                current + 100,
                current + 200,
                10,
                true,
                true,
                &clock,
                test_scenario::ctx(scenario),
            );

            test_scenario::return_shared<GlobalConfig>(global);
            // test_scenario::return_shared<Clock>(clock);
        };

        test_scenario::next_tx(scenario, SENDER); {
            let stream = test_scenario::take_shared<StreamInfo<STREAM_TESTS>>(scenario);
            // let coin11 = test_scenario::take_from_sender<Coin<STREAM_TESTS>>(scenario);
            let coin2 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin2_id);
            assert!(coin::value(&coin2) == 20000, 0);
            assert!(stream::pauseable(&stream, SENDER), 0);
            assert!(!stream::pauseable(&stream, RECIPIENT), 0);
            assert!(stream::closeable(&stream, SENDER), 0);
            assert!(!stream::closeable(&stream, RECIPIENT), 0);

            test_scenario::return_shared<StreamInfo<STREAM_TESTS>>(stream);
            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin2);
        };

        test_scenario::next_tx(scenario, SENDER); {
            let sender_cap = test_scenario::take_from_sender<SenderCap>(scenario);
            let stream = test_scenario::take_shared<StreamInfo<STREAM_TESTS>>(scenario);
            // let clock = test_scenario::take_shared<Clock>(scenario);
            let current = clock::timestamp_ms(&clock)/1000;

            // let coin3 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin3_id);
            let coin4 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin4_id);

            // let payments = vector::empty<Coin<STREAM_TESTS>>();
            // vector::push_back(&mut payments, coin3);
            // vector::push_back(&mut payments, coin4);
            stream::extend(
                &sender_cap,
                &mut stream,
                coin4,
                current + 300,
                test_scenario::ctx(scenario),
            );

            clock::increment_for_testing(&mut clock, 110*1000);
            test_scenario::return_to_sender<SenderCap>(scenario, sender_cap);
            test_scenario::return_shared<StreamInfo<STREAM_TESTS>>(stream);
            // test_scenario::return_shared<Clock>(clock);
        };

        test_scenario::next_tx(scenario, SENDER); {
            // let coin11 = test_scenario::take_from_sender<Coin<STREAM_TESTS>>(scenario);
            let coin4 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin4_id);

            assert!(coin::value(&coin4) == 20000, 0);

            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin4);
        };

        test_scenario::next_tx(scenario, RECIPIENT); {

            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let stream = test_scenario::take_shared<StreamInfo<STREAM_TESTS>>(scenario);

            stream::withdraw(
                &mut stream,
                &clock,
                test_scenario::ctx(scenario),
            );

            clock::increment_for_testing(&mut clock, 200*1000);
            test_scenario::return_shared<GlobalConfig>(global);
            test_scenario::return_shared<StreamInfo<STREAM_TESTS>>(stream);
            // test_scenario::return_shared<Clock>(clock);
        };

        test_scenario::next_tx(scenario, RECIPIENT); {
            let coin11 = test_scenario::take_from_sender<Coin<STREAM_TESTS>>(scenario);

            assert!(coin::value(&coin11) == 8000*(10000-100)/10000, 0);

            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin11);
        };

        test_scenario::next_tx(scenario, OWNER); {
            let coin11 = test_scenario::take_from_sender<Coin<STREAM_TESTS>>(scenario);

            assert!(coin::value(&coin11) == 8000*100/10000, 0);

            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin11);
        };

        test_scenario::next_tx(scenario, SENDER); {

            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let stream = test_scenario::take_shared<StreamInfo<STREAM_TESTS>>(scenario);
            // let clock = test_scenario::take_shared<Clock>(scenario);

            stream::withdraw(
                &mut stream,
                &clock,
                test_scenario::ctx(scenario),
            );

            test_scenario::return_shared<GlobalConfig>(global);
            test_scenario::return_shared<StreamInfo<STREAM_TESTS>>(stream);
            // test_scenario::return_shared<Clock>(clock);
        };

        test_scenario::next_tx(scenario, RECIPIENT); {
            let coin11 = test_scenario::take_from_sender<Coin<STREAM_TESTS>>(scenario);

            assert!(coin::value(&coin11) == 152000*(10000-100)/10000, 0);

            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin11);
        };

        test_scenario::next_tx(scenario, OWNER); {
            let coin11 = test_scenario::take_from_sender<Coin<STREAM_TESTS>>(scenario);
            assert!(coin::value(&coin11) == 152000*100/10000, 0);

            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin11);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = stream::ERR_STREAM_PAUSE_STATUS)]
    fun stream_paused(){

        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        //init module
        let ctx = test_scenario::ctx(scenario);
        stream::init_test(ctx);
        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);
        let ctx = test_scenario::ctx(scenario);
        let witness = STREAM_TESTS{};
        let (treasury, metadata) = coin::create_currency(
            witness,
            6,
            b"COIN_TESTS",
            b"coin_name",
            b"description",
            option::some(url::new_unsafe_from_bytes(b"icon_url")),
            ctx,
        );
        // let coin1 = from_balance(
        //     mint_balance<STREAM_TESTS>(&mut treasury, 10000),
        //     test_scenario::ctx(scenario)
        // );
        let coin2 = from_balance(
            mint_balance<STREAM_TESTS>(&mut treasury, 100000),
            test_scenario::ctx(scenario)
        );
        // let coin3 = from_balance(
        //     mint_balance<STREAM_TESTS>(&mut treasury, 20000),
        //     test_scenario::ctx(scenario)
        // );
        let coin4 = from_balance(
            mint_balance<STREAM_TESTS>(&mut treasury, 100000),
            test_scenario::ctx(scenario)
        );
        // let coin5 = from_balance(
        //     mint_balance<STREAM_TESTS>(&mut treasury, 500000),
        //     test_scenario::ctx(scenario)
        // );
        // let coin1_id = object::id(&coin1);
        let coin2_id = object::id(&coin2);
        // let coin3_id = object::id(&coin3);
        let coin4_id = object::id(&coin4);
        // let coin5_id = object::id(&coin5);
        // transfer::public_transfer(coin1, SENDER);
        transfer::public_transfer(coin2, SENDER);
        // transfer::public_transfer(coin3, SENDER);
        transfer::public_transfer(coin4, SENDER);
        // transfer::public_transfer(coin5, SENDER);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, OWNER);

        test_scenario::next_tx(scenario, OWNER); {
            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            stream::register_coin<STREAM_TESTS>(&manCap, &mut global, 100, ctx);

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
            test_scenario::return_shared<GlobalConfig>(global);
        };

        test_scenario::next_tx(scenario, SENDER); {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            // let clock = test_scenario::take_shared<Clock>(scenario);
            let current = clock::timestamp_ms(&clock)/1000;

            // let coin1 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin1_id);
            let coin2 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin2_id);

            // let payments = vector::empty<Coin<STREAM_TESTS>>();
            // vector::push_back(&mut payments, coin1);
            // vector::push_back(&mut payments, coin2);
            stream::create<STREAM_TESTS>(
                &mut global,
                coin2,
                string::utf8( b"test1"),
                string::utf8( b"test1"),
                RECIPIENT,
                80000,
                current + 100,
                current + 200,
                10,
                true,
                true,
                &clock,
                test_scenario::ctx(scenario),
            );

            clock::increment_for_testing(&mut clock, 110*1000);
            test_scenario::return_shared<GlobalConfig>(global);
            // test_scenario::return_shared<Clock>(clock);
        };

        test_scenario::next_tx(scenario, SENDER); {
            let coin2 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin2_id);
            assert!(coin::value(&coin2) == 20000, 0);

            test_scenario::return_to_sender<Coin<STREAM_TESTS>>(scenario, coin2);
        };

        test_scenario::next_tx(scenario, SENDER); {

            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let stream = test_scenario::take_shared<StreamInfo<STREAM_TESTS>>(scenario);
            // let clock = test_scenario::take_shared<Clock>(scenario);
            let sender_cap = test_scenario::take_from_sender<SenderCap>(scenario);

            stream::pause(
                &sender_cap,
                &mut stream,
                &clock,
                test_scenario::ctx(scenario),
            );

            clock::increment_for_testing(&mut clock, 200*1000);
            test_scenario::return_to_sender<SenderCap>(scenario, sender_cap);
            test_scenario::return_shared<GlobalConfig>(global);
            test_scenario::return_shared<StreamInfo<STREAM_TESTS>>(stream);
            // test_scenario::return_shared<Clock>(clock);
        };

        test_scenario::next_tx(scenario, SENDER); {
            let sender_cap = test_scenario::take_from_sender<SenderCap>(scenario);
            let stream = test_scenario::take_shared<StreamInfo<STREAM_TESTS>>(scenario);
            // let clock = test_scenario::take_shared<Clock>(scenario);
            let current = clock::timestamp_ms(&clock)/1000;

            // let coin3 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin3_id);
            let coin4 = test_scenario::take_from_sender_by_id<Coin<STREAM_TESTS>>(scenario, coin4_id);

            // let payments = vector::empty<Coin<STREAM_TESTS>>();
            // vector::push_back(&mut payments, coin3);
            // vector::push_back(&mut payments, coin4);
            stream::extend(
                &sender_cap,
                &mut stream,
                coin4,
                current + 300,
                test_scenario::ctx(scenario),
            );

            test_scenario::return_to_sender<SenderCap>(scenario, sender_cap);
            test_scenario::return_shared<StreamInfo<STREAM_TESTS>>(stream);
            // test_scenario::return_shared<Clock>(clock);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

}
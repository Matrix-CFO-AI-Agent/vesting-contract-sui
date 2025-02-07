const { devnetConnection, JsonRpcProvider, Connection, Ed25519Keypair, RawSigner, TransactionBlock } = require("@mysten/sui.js");
const { mnemonic1, mnemonic2, mnemonic3, mnemonic }  = require('./secrets.json');

const testnetConnection = new Connection({
    fullnode: 'https://fullnode.testnet.sui.io:443/',
    faucet: 'https://faucet.testnet.sui.io/gas',
});

const path = "m/44'/784'/0'/0'/0'";
const keypair1 = Ed25519Keypair.deriveKeypair(mnemonic1, path);
const keypair2 = Ed25519Keypair.deriveKeypair(mnemonic2, path);
const keypair3 = Ed25519Keypair.deriveKeypair(mnemonic3, path);
const keypair = Ed25519Keypair.deriveKeypair(mnemonic, path);

console.log(keypair1.getPublicKey().toSuiAddress());
console.log(keypair2.getPublicKey().toSuiAddress());
console.log(keypair3.getPublicKey().toSuiAddress());
console.log(keypair.getPublicKey().toSuiAddress());

const provider = new JsonRpcProvider(testnetConnection);


async function main() {

    // await provider.requestSuiFromFaucet(keypair.getPublicKey().toSuiAddress());

    //get object global_config
    let txn = await provider.getObject({
        id: '0x2217bc9922316837220dfedbd1068533ee2dfd1a3073c16c76fb376e23b17d7e',
        // fetch the object content field
        options: { showContent: true },
    });

    console.log(txn);
    /****
     * {
     *   data: {
     *     objectId: '0x2217bc9922316837220dfedbd1068533ee2dfd1a3073c16c76fb376e23b17d7e',
     *     version: 578946,
     *     digest: 'CFbyiugC6ThaCCjYxmeyAfQ2MmjtsTNqwKZm5yfbUow8',
     *     content: {
     *       dataType: 'moveObject',
     *       type: '0x21383c9973e51348db3eaecdb95034eca8171bd00f1e3de4ab85ea4f2d697587::stream::GlobalConfig',
     *       hasPublicTransfer: false,
     *       fields: [Object]
     *     }
     *   }
     * }
     ****/
    console.log(txn.data.content.fields);
    /****
     * {
     *   coin_configs: {
     *     type: '0x2::table::Table<0x1::string::String, 0x21383c9973e51348db3eaecdb95034eca8171bd00f1e3de4ab85ea4f2d697587::stream::CoinConfig>',
     *     fields: { id: [Object], size: '1' }
     *   },
     *   fee_recipient: '0xb6dedb535d8fcb9b2bb12313737c6b094a48abc494103da8dcac129e21f396fb',
     *   id: {
     *     id: '0x2217bc9922316837220dfedbd1068533ee2dfd1a3073c16c76fb376e23b17d7e'
     *   },
     *   incoming_stream: {
     *     type: '0x2::table::Table<address, vector<0x2::object::ID>>',
     *     fields: { id: [Object], size: '1' }
     *   },
     *   outgoing_stream: {
     *     type: '0x2::table::Table<address, vector<0x2::object::ID>>',
     *     fields: { id: [Object], size: '1' }
     *   }
     * }
     ****/
    console.log(txn.data.content.fields.incoming_stream.fields.id);
    /****
     * {
     *   id: '0xc692b2acc82596239bdec03005ed2ae9815e05f7ec32536c1169ba5328e15675'
     * }
     ****/

    //get all dynamic filed of incoming_stream
    txn = await  provider.getDynamicFields({
        parentId: "0xc692b2acc82596239bdec03005ed2ae9815e05f7ec32536c1169ba5328e15675",
    })
    console.log(txn);
    /****
     * {
     *   data: [
     *     {
     *       name: [Object],
     *       bcsName: 'B9LFczyvjf6kLaYwbQBcvDiNZf7xwkAirkqogNWMU9Xb',
     *       type: 'DynamicField',
     *       objectType: 'vector<0x2::object::ID>',
     *       objectId: '0xd16049d74004cc8690e351edfe5eacb7a4408ebbdfea3870ca9177de2b907503',
     *       version: 578946,
     *       digest: '5hp1uAGUVkapvdDmjT2j7vieer9WCcV9xZtAaPvnTBpp'
     *     }
     *   ],
     *   nextCursor: '0xd16049d74004cc8690e351edfe5eacb7a4408ebbdfea3870ca9177de2b907503',
     *   hasNextPage: false
     * }
     ****/
    console.log(txn.data[0].name);
    /****
     * {
     *   type: 'address',
     *   value: '0x96b748bcf4bbea124ca405982ba6cd1cf17ee234b0d555b3e29e4e085ad87966'
     * }
     ****/


    //get a dynamic filed of incoming_stream
    txn = await  provider.getDynamicFieldObject({
        parentId: "0xc692b2acc82596239bdec03005ed2ae9815e05f7ec32536c1169ba5328e15675",
        name: {
            type: 'address',
            value: '0x96b748bcf4bbea124ca405982ba6cd1cf17ee234b0d555b3e29e4e085ad87966'
        },
    })
    console.log(txn);
    /****
     * {
     *   data: {
     *     objectId: '0xd16049d74004cc8690e351edfe5eacb7a4408ebbdfea3870ca9177de2b907503',
     *     version: 578946,
     *     digest: '5hp1uAGUVkapvdDmjT2j7vieer9WCcV9xZtAaPvnTBpp',
     *     type: '0x2::dynamic_field::Field<address, vector<0x2::object::ID>>',
     *     owner: {
     *       ObjectOwner: '0xc692b2acc82596239bdec03005ed2ae9815e05f7ec32536c1169ba5328e15675'
     *     },
     *     previousTransaction: '6Ym3LHQLGsFkyyZy4Ezbd6rCnVYkTtnbUgzM2eAtqRRu',
     *     storageRebate: 28,
     *     content: {
     *       dataType: 'moveObject',
     *       type: '0x2::dynamic_field::Field<address, vector<0x2::object::ID>>',
     *       hasPublicTransfer: false,
     *       fields: [Object]
     *     }
     *   }
     * }
     ****/

    //get table object of incoming_stream
    txn = await provider.getObject({
        id: '0xd16049d74004cc8690e351edfe5eacb7a4408ebbdfea3870ca9177de2b907503',
        // fetch the object content field
        options: { showContent: true },
    });

    console.log(txn);
    /****
     * {
     *   data: {
     *     objectId: '0xd16049d74004cc8690e351edfe5eacb7a4408ebbdfea3870ca9177de2b907503',
     *     version: 578946,
     *     digest: '5hp1uAGUVkapvdDmjT2j7vieer9WCcV9xZtAaPvnTBpp',
     *     content: {
     *       dataType: 'moveObject',
     *       type: '0x2::dynamic_field::Field<address, vector<0x2::object::ID>>',
     *       hasPublicTransfer: false,
     *       fields: [Object]
     *     }
     *   }
     * }
     ****/

    console.log(txn.data.content.fields);
    /****
     * {
     *   id: {
     *     id: '0xd16049d74004cc8690e351edfe5eacb7a4408ebbdfea3870ca9177de2b907503'
     *   },
     *   name: '0x96b748bcf4bbea124ca405982ba6cd1cf17ee234b0d555b3e29e4e085ad87966',
     *   value: [
     *     '0xe1366748ab89018f975b75dce2781ee786eb6e027be5adf732783eab225e04b7'
     *   ]
     * }
     ****/
}

main().catch(console.error);
const { devnetConnection, SUI_CLOCK_OBJECT_ID, JsonRpcProvider, Connection, Ed25519Keypair, RawSigner, TransactionBlock } = require("@mysten/sui.js");
const { mnemonic }  = require('./secrets.json');

const testnetConnection = new Connection({
    fullnode: 'https://explorer-rpc.testnet.sui.io:443/',
    faucet: 'https://faucet.testnet.sui.io/gas',
});

const path = "m/44'/784'/0'/0'/0'";
const keypair = Ed25519Keypair.deriveKeypair(mnemonic, path);

console.log(keypair.getPublicKey().toSuiAddress());

const provider = new JsonRpcProvider(testnetConnection);

async function main() {
    //await provider.requestSuiFromFaucet(address);
    const signer = new RawSigner(
        keypair,
        provider
    );
    const packageObjectId = '0x8adcbe225d672f56ee96abc51481887e106661ef899ccc5a7dec7161b790be69';
    const tx = new TransactionBlock()

    // Split a coin object off of the gas object:
    const coins = tx.splitCoins(tx.gas, [tx.pure(1000000)]);

    tx.moveCall({
        target: `${packageObjectId}::stream::create`,
        typeArguments: [
            "0x2::sui::SUI",
        ],
        arguments: [
            tx.object('0x95b3e1f1fefef450e4fdbf6d5279ca2421429a5bd2ce7da50cf32b62c5f326b2'),
            coins[0],
            tx.pure('true'),
            tx.pure('true'),
            tx.pure('0x58e3511aa31f0bd694d95ad6148e33cb45c52356eca673847c51dd3b13a66983'),
            tx.pure(1000000),
            tx.pure(1688918626),  //s
            tx.pure(1688928626),  //s
            tx.pure(1),             //s
            tx.pure(true),
            tx.pure(true),
            tx.object(SUI_CLOCK_OBJECT_ID),
        ]
    })
    tx.setGasBudget(10000000);
    const result = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
    });
    console.log(result);
}

main().catch(console.error);
const { SUI_CLOCK_OBJECT_ID, JsonRpcProvider, Connection, Ed25519Keypair, RawSigner, TransactionBlock } = require("@mysten/sui.js");
const { mnemonic }  = require('./secrets.json');

const testnetConnection = new Connection({
    fullnode: 'https://fullnode.testnet.sui.io:443/',
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
    const packageObjectId = '0x21383c9973e51348db3eaecdb95034eca8171bd00f1e3de4ab85ea4f2d697587';
    const tx = new TransactionBlock()

    tx.moveCall({
        target: `${packageObjectId}::stream::close_from_sender`,
        typeArguments: [
            "0x2::sui::SUI",
        ],
        arguments: [
            tx.object('0xb511929525408fcc7ceec20b30b9ce46d5ba6ee4a6ab83788e5cddba24dbba70'),
            tx.object('0xe1366748ab89018f975b75dce2781ee786eb6e027be5adf732783eab225e04b7'),
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
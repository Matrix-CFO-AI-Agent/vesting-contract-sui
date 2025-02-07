const { JsonRpcProvider, Connection, Ed25519Keypair, RawSigner, TransactionBlock } = require("@mysten/sui.js");
const { mnemonic }  = require('./secrets.json');

const testnetConnection = new Connection({
    fullnode: 'https://wallet-rpc.testnet.sui.io:443/',
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
        target: `${packageObjectId}::stream::register_coin`,
        typeArguments: [
            "0x2::sui::SUI",
        ],
        arguments: [
            tx.pure('0x0d6a41f4f7aa616b52985e0e51ac16c6956b338d8e8a2e0911c4dc1f2fc1f7e5'),
            tx.pure('0x2217bc9922316837220dfedbd1068533ee2dfd1a3073c16c76fb376e23b17d7e'),
            tx.pure('100')
        ]
    })
    const result = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
    });

    console.log(result);
}

main().catch(console.error);
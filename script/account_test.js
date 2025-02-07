const { devnetConnection, JsonRpcProvider, Connection, Ed25519Keypair, RawSigner, TransactionBlock } = require("@mysten/sui.js");
const { mnemonic1, mnemonic2, mnemonic3, mnemonic }  = require('./secrets.json');

const testnetConnection = new Connection({
    fullnode: 'https://explorer-rpc.testnet.sui.io:443/',
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

const provider = new JsonRpcProvider(devnetConnection);


async function main() {

    await provider.requestSuiFromFaucet(keypair.getPublicKey().toSuiAddress());

}

main().catch(console.error);
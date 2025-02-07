# MoveFlow-Sui
A crypto asset streaming protocol
> Testnet Demo: https://www.moveflow.xyz/
>

# Introduction
## In Brief
MOVEFLOW is an crypto asset streaming protocol built on Move ecosystem.

MOVEFLOW is able to transfer assets on chain according to predefined rules. With one transaction, funds will flow from your wallet to the recipient real-time(by second), to conduct timely financial transactions without intermediaries.

## Background
In 2016, Andreas M. Antonopoulos delivered this exceptional keynote on “Streaming Money” at the Special Edition of the [Bitcoin Wednesday Conference at the Eye Film Museum in Amsterdam on 19 October, 2016](https://www.youtube.com/watch?v=l235ydAx5oQ).

In 2018, Paul Razvan Berg created the technical standard of streaming payment: [EIP-1620: Money Streaming](https://eips.ethereum.org/EIPS/eip-1620).

As of the end of 2022, most prominent public blockchains have their web3 asset streaming protocol like: Sablier, Superfluid, Roketo, Zebec, Calamus, LlamaPay, etc. And we believe Sui needs its own web3 asset streaming protocol, whose extremely high TPS and low transaction bring excellent user expreience when conducting transactions.

## Features
* Asset stream(transfer) by customize interval
* pause-able
* extendable
* closeable

# contract addresses
## devnet

packageId = 0x281c5b3176b09a9a02f8fdeb82622156e43fd185f19231975d72b4a82835d083
0x2::package::UpgradeCap = 0xde4515f2aabba0d726038b5d2d736428ba9ed8032504aa8f7436655b8efbc712
{packageId}::stream::ManageCap = 0xef2d57439ea724c632ace0e647f4410ca1f46e77c8d1d8c093b8b7639aa1d1d1
{packageId}::stream::GlobalConfig = 0x26524ad2da1d698da821b01425a0ec534883f8bd12a2783767698f626536bd12
coin_configs = 0x333b86ec5e1375bcab8146450f858187622c9815cd57cde8554d52994cd9b993
incoming_stream = 0xe16d3a248697e6692e9b06295c0f5ac93d559003a14a2417553a6477d37438b1
outgoing_stream = 0x748c03c99eb73adea44446b1efe3b4ae34e2c1e29db3acf1b518b3f1789d5e1a


## testnet
packageId = 0x8adcbe225d672f56ee96abc51481887e106661ef899ccc5a7dec7161b790be69
0x2::package::UpgradeCap = 0xfa0528d86efd3d2d6fca79890483970d9478c404dd6fc26b2259670aa57fdb70
{packageId}::stream::ManageCap = 0x1f683a52f9e83f868349e9f6a6ed4de9913b6eb88318b5ce7d0b52e9fddc6295
{packageId}::stream::GlobalConfig = 0x95b3e1f1fefef450e4fdbf6d5279ca2421429a5bd2ce7da50cf32b62c5f326b2
coin_configs = 0x64d9d712a435f282cbd5756b7b3d215a5ef81f385ac3339a6b3d23119e4c3a52
incoming_stream = 0x2fb090feef48968b937ff470273dcab417d4ad870d7e336fcd7b656fdeeb936a
outgoing_stream = 0x204f815be7a8eaf535e4899556a14d07dd2e29a35148ac249577858ba9583b8a
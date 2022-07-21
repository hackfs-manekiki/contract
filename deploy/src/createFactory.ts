import { ethers } from 'ethers'
import * as FactoryArtifact from '../../out/Factory.sol/Factory.json'

async function main() {
    const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    const factory = new ethers.ContractFactory(FactoryArtifact.abi, FactoryArtifact.bytecode.object, wallet)
    const vaultFactory = await factory.deploy()
    console.log(`factory: ${vaultFactory.address}`)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
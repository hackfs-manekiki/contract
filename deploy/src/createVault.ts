import { ethers } from 'ethers'
import * as FactoryArtifact from '../../out/Factory.sol/Factory.json'

async function main() {
    const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
    const factoryAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    const vaultFactory = new ethers.Contract(factoryAddress, FactoryArtifact.abi, wallet)
    const param = {
        name: 'test',
        admins: ['0x70997970c51812dc3a010c7d01b50e0d17dc79c8', '0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc'],
        approvers: [
            {
                approver: '0x90f79bf6eb2c4f870365e785982e1f101e93b906',
                budget: '1000000000'
            }
        ]
    }
    await vaultFactory.createVault(param)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
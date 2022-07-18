import { ethers } from 'ethers'
import * as VaultArtifact from '../../out/Vault.sol/Vault.json'

async function main() {
    const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    const factory = new ethers.ContractFactory(VaultArtifact.abi, VaultArtifact.bytecode.object, wallet)
    const weights: any[] = [{
        owner: '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266',
        weight: 1
    }]
    const contract = await factory.deploy(weights, 1)
    // TRANSFER(address payable to,uint256 amount,uint256 nounce)
    const EIP721_DOMAIN_TYPE = {
        EIP712Domain: [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "chainId", type: "uint256" },
            { name: "verifyingContract", type: "address" },
        ]
    }
    const EIP721_TRANSFER_TYPE = {
        TRANSFER: [
            { type: "address", name: 'to' },
            { type: 'uint256', name: 'amount' },
            { type: 'uint256', name: 'nonce' }
        ]
    }

    const domain = {
        name: 'ManekiVault',
        version: '1.0.0',
        chainId: await wallet.getChainId(),
        verifyingContract: contract.address
    }
    const transferObj = {
        to: wallet.address,
        amount: ethers.utils.parseUnits('0.5', 'ether').toString(),
        nonce: 1
    }
    const hash = ethers.utils._TypedDataEncoder.hash(domain, EIP721_TRANSFER_TYPE, transferObj)

    const signature = await wallet._signTypedData({
        name: 'ManekiVault',
        version: '1.0.0',
        chainId: await wallet.getChainId(),
        verifyingContract: contract.address
    }, EIP721_TRANSFER_TYPE, {
        to: wallet.address,
        amount: ethers.utils.parseUnits('0.5', 'ether').toString(),
        nonce: 1
    })
    console.log(await contract.checkSignature(wallet.address, hash, signature))
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
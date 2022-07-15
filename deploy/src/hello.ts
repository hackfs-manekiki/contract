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
    const hash = await contract.hashTransfer(wallet.address, ethers.utils.parseUnits('0.5', 'ether'), 1)
    console.log(`hash from contract: ${hash}`)
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
    console.log(await wallet.getChainId())
    console.log(ethers.utils._TypedDataEncoder.hashStruct('EIP712Domain', EIP721_DOMAIN_TYPE, {
        name: 'ManekiVault',
        version: '1.0.0',
        chainId: await wallet.getChainId(),
        verifyingContract: contract.address
    }))
    console.log(ethers.utils._TypedDataEncoder.hashDomain({
        name: 'ManekiVault',
        version: '1.0.0',
        chainId: await wallet.getChainId(),
        verifyingContract: contract.address
    }))
    const domain = await contract.domainSeparatorV4()
    console.log(domain)

    console.log(ethers.utils._TypedDataEncoder.hashStruct('TRANSFER', EIP721_TRANSFER_TYPE, {
        to: wallet.address,
        amount: ethers.utils.parseUnits('0.5', 'ether').toString(),
        nonce: 1
    }))
    const dataHash = await contract.getHash(wallet.address, ethers.utils.parseUnits('0.5', 'ether').toString(), 1)
    await console.log(dataHash)
    console.log(ethers.utils.keccak256(ethers.utils.hexConcat([
        '0x1901',
        domain,
        dataHash
    ])))
    const hash2 = ethers.utils._TypedDataEncoder.hash({
        name: 'ManekiVault',
        version: '1.0.0',
        chainId: await wallet.getChainId(),
        verifyingContract: contract.address
    }, EIP721_TRANSFER_TYPE, {
        to: wallet.address,
        amount: ethers.utils.parseUnits('0.5', 'ether').toString(),
        nonce: 1
    })
    console.log(`hash from ethers: ${hash2}`)
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
    console.log(await contract.checkSignature(wallet.address, hash2, signature))
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
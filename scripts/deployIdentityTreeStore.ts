import { DeployHelper } from "../helpers/DeployHelper";

(async () => {
  const deployHelper = await DeployHelper.initialize();

  // const stateContractAddress = process.env.STATE_CONTRACT_ADDRESS || "0x8C511bc309c7301B868d8018951254ff89Ee1C22";
  const stateContractAddress = process.env.STATE_CONTRACT_ADDRESS || "0x8B2033C1da75FC4f673C998833e284190Bb43D0E";
  // const stateContractAddress = process.env.STATE_CONTRACT_ADDRESS || "0x830b0A75531497C9011865340AB8EFC72Ce7068a";
  // const stateContractAddress = process.env.STATE_CONTRACT_ADDRESS || "0x8B2033C1da75FC4f673C998833e284190Bb43D0E";
  // const stateContractAddress = process.env.STATE_CONTRACT_ADDRESS || "0x8B2033C1da75FC4f673C998833e284190Bb43D0E";

  await deployHelper.deployIdentityTreeStore(stateContractAddress);
})();

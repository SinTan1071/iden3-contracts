pragma solidity ^0.4.24;

import './lib/DelegateProxySlotStorage.sol';
import './lib/IDen3lib.sol';

import './IDen3SlotStorage.sol';
import './RootCommits.sol';


contract IDen3Impl is
   DelegateProxySlotStorage,
   IDen3SlotStorage,
   IDen3lib {

   uint256         public   lastNonce;  // last nonce

   struct KSign {
       uint64  validUntil;
       bytes32 appid;
       bytes32 authz;
   }

   mapping(address=>KSign) ksigns;     // a caché for ksigns
   
   constructor()
   IDen3SlotStorage(0x0)
   public {
       __setProxyImpl(0x0);
       __setProxyRecovery(0x0);
       __setProxyRecoveryProp(0x0);
   }

   function changeRelayer(address _relayer) public {
        (,address recovery,) = __getProxyInfo();
        require (msg.sender == recovery);
        __setRelay(_relayer);
   }

   // use this function to register ksign claims
   function mustVerifyAuth(
       address _to,
       address _caller,
       bytes   _auth
  ) view internal {
       
       Memory.Walker memory w = Memory.walk(_auth);       

       // check version
       require(w.readUint16()==1);

       // verify ksignclaim  --------------------------------------------------
       (bool kok, KSignClaim memory kclaim) = unpackKSignClaim(w.readBytes());
       require(kok && _caller==kclaim.key);
       require(now >= kclaim.validFrom && now <= kclaim.validUntil); 

       bytes32 kclaimRoot = w.readBytes32();
       require(checkProof(kclaimRoot,w.readBytes(),kclaim.hi,kclaim.ht,140));

       // verify setrootclaim  --------------------------------------------------
       (bool rok, SetRootClaim memory rclaim) = unpackSetRootClaim(w.readBytes());
       require(rok,"ok");
       require(rclaim.root == kclaimRoot,"rclaim.root == kclaimRoot");
       // TODO: require(rclaim.ethid == address(this),"rclaim.ethid == address(this)");
 
       bytes32 rclaimRoot = w.readBytes32();
       require(checkProof(rclaimRoot,w.readBytes(),rclaim.hi,rclaim.ht,140));
       
       uint64  rclaimSigDate = w.readUint64();
       bytes   memory rclaimSig = w.readBytes();

       // check the signature is fresh and done by the relayer
       address signer = ecrecover2(
           keccak256(abi.encodePacked(rclaimRoot,rclaimSigDate)),
           rclaimSig,
           0
       );
       require(now < rclaimSigDate + 3600 && signer == __getRelay());

       if (kclaim.appid == keccak256("address")) {
            require(address(kclaim.authz) == _to);
       }
   }

   function forward(
       address _to,    // destination
       bytes   _data,  // data to recieve
       uint256 _value, // value to send 
       uint256 _gas,   // maximum execution gas
       bytes   _sig,   // signature made by a KSign
       bytes   _auth   // claims + proofs
   ) public {
        
       lastNonce++;

       // EIP191 compliant 0x19 0x00
       bytes32 hash=keccak256(abi.encodePacked(
          byte(0x19),byte(0),
          this,lastNonce,
          _to,_data, _value, _gas,
          _auth
       ));
    
       // get the signature
       address signer=IDen3lib.ecrecover2(hash,_sig,0);

       mustVerifyAuth(_to, signer,_auth);

       require(_to.call.gas(_gas).value(_value)(_data));
   }
   
}

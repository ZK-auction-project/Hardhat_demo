// SPDX-License-Identifier: MIT
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract VerifierRange {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x1864c2237f57a26792ede584dbc7b02420091036889aefa87efe585a17ac97fd), uint256(0x2abe13bedd1656dc0f2e9075d772d4f1f107f11145b46fbd9ae59af81cf2feff));
        vk.beta = Pairing.G2Point([uint256(0x2127be5dd5c9362ac5fc358cf8c4e86520e1ff74aec117eae62e416e18b5b4dc), uint256(0x1ffaced8ab31bbf8afd56fed0836e42ea405aeba2f80d83bb3fb6aa585d776fa)], [uint256(0x113dc47f6a5ccaab13fdd747a620c0acee98296c48207540bf2dc294bca4d970), uint256(0x10e89c0dd9035c70f60e8bc0b00b810352c44f57020988201ce941322fd777fd)]);
        vk.gamma = Pairing.G2Point([uint256(0x28a3a9069a8827498619e712d848382ccc76351f96c6733929993eaa53679af9), uint256(0x096c06af4cfdb0d797d9dce824cc3217a3201aa5b1e8e11320a7a9b5fa69d82a)], [uint256(0x18d4b1c42a8abcd791ff5ec0e99e19ec4aff28bf6defeaeeee85ecc685920ec4), uint256(0x124103b0665e6782dc43d58611c926541dc869db32fec352c34b33339d36fc48)]);
        vk.delta = Pairing.G2Point([uint256(0x133cf36ee057e12200ca691ed5ccbe1ea7d2a735352b4de333f3da7ff7ab29e7), uint256(0x03fb7303af2c342e2984c1ca3750a9a54ca08f5fcbf247321224f28af5f28f49)], [uint256(0x09c43f91957b8f4a5be84103901f80b94bd899fb5abb6f95a892fd9ac49d9188), uint256(0x072ef60a71ed9ed4c1f1be95865698c73459888b76be46deb499919ac896a110)]);
        vk.gamma_abc = new Pairing.G1Point[](2);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x17b7de9f370df8c2cd9f4f277ca1a6ebbad5d35e825b54a5eaaba9d454bb5947), uint256(0x066361a2b0cc427adeda1da21e071b102f21e7c3bb8fba2a0baed364996f55cf));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1fd32d948a73edc34b7f21416254830175b04c7ad243158aed90a8fdf395cd93), uint256(0x221731609e489f6208df7515367d3674c4a2f4ed2c6f015bce0ffd2fa6bdabf8));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[1] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](1);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

contract VerifierCompare {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x10e694049079a7ce71e71ef01a09b065a59862896bb35127efdb27da60585c69), uint256(0x173ef47479547bd0df1df45b5c47937a5d8fe4e92063a5cd1de83cbd79259efe));
        vk.beta = Pairing.G2Point([uint256(0x215605370671157cd56054de1a6ab2d8e08ebd16941ca8be83e0550683895c18), uint256(0x0b5ddb4be04d80faf91533ac085313c3d59eb0019abb7452a9f38c8d224ba4ec)], [uint256(0x013f83cf20b5d83cb733f15613a6a159a2ca417064b84222f3650d7070b3f661), uint256(0x155c7856d994f861b192b531d6353e1029c4b0ffe4342be7a126ff755a4ba310)]);
        vk.gamma = Pairing.G2Point([uint256(0x10eafce528a817fa34159ad694d0c8c7fccf429f8467ab7f5b95362e71d8771d), uint256(0x045faf90cbf6e359b1e5fe60cdcd11622bfbf160b8c3cf15a65938052fe8b99b)], [uint256(0x1042d35d8d4606eafd0e31a199cd68d7952b6d19d9f5ac5750a8c473078a6db0), uint256(0x1e84e9c4ce0993ed913406d0ed794bf9b667a595077cd97359df24b6096b439d)]);
        vk.delta = Pairing.G2Point([uint256(0x2f18ff87b400a282f90e8c38778539efd0855736175b9deffb0cfdb7861cb5eb), uint256(0x18c952c336629f8cca6d4d3927d4c9e47d4a178828bad3edb555db7dc527a612)], [uint256(0x1dd03f76033f50933e1e5b603d4d78bc70a827293e68187fa5d07ea2e935dd99), uint256(0x0ad3379f6cebb1cee4ac823f3bc2afa0f40ace86a7923466ec53bf1aad9b9976)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0db19b4824314d61fd82255d6b049c7ab25e68d2054ab63ee450c6afde729378), uint256(0x1fc2d634b5323fad470b821018199483f6d48f68cf79a5aeaf8b246488a35fe8));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x08046d3db2d5b2975803072ce36b81d78584054f5aaa7c27d2b7779a2d19192a), uint256(0x22a71a3354324ab9951470aebe9929dc3604052befd47f85d172b35b953634b6));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0d5f15f50db723a2b444bb92640d1aeb565f756dd972e74ee31dfe221acbc2ba), uint256(0x19a9bc0afabd60c33acf02c45dc5fcdebffe4013ec7fb5f644738f3fc6e58944));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2a30dd3fb3ea83d31dca6a1739d275262a1cad02c30d5dbd8e2067cc14f56352), uint256(0x0e5374c9fefcd3b241d3b9e45022f93d7d982be9d13da4841aeac1dd290f6c56));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x241b5bcc1aa1be2e93c2840e4246e6ead3f48d1a1b3a9d1de640c1188e6039f9), uint256(0x067b9d61cf6dd1f04357873488e345f7e5e28296abad51efde50e82945dd61ba));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1ad9e13d0de181ff2c15ee0a66eb5142f5ed5e0d86a2734ccfd9a986f41896d4), uint256(0x0d695a369e12d1cd1107916e95218bf9e3c9ad8ff3856fbe8e343db7d3b3c06e));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1194fe975d2135fbc0961e60ffe831a36d40eea1e0002c6adb95be812d6763a7), uint256(0x2a098f06e6aca7328d0abca0219c787955b4ad1b7e1c1e61429d5f1a8afb529b));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0faa1e898eccf67eb23884c1c25315d20dfd5d75f244e9721854f8059444e30d), uint256(0x09ac9ab38939b5936723e0000660a7a3494063a125f595335cca8b7ba63fdefc));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x266ba77bf3e0f7464d47bd2f82bec242bf2c6bfa1dcaa532bd58310ed6dec0c3), uint256(0x02505dfb2188a76d2f860e1dbfd2f3cc85086310096df8a7811a0f75c3b27650));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x233168e5e433377147e54defb1eb6c1c93cc303ef4818b93e60f6b0ca9962a90), uint256(0x13fd58757ee35bae79366414cfc72dfaba413f48e6306cc890e30e73014911e8));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x063c0be313812853012824f17ebece0914618fd404da34789140006f64edac28), uint256(0x2755f57e608b600ddb7be01e79486c3201de0100b4fedeef385d7583b1a08e2d));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[10] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](10);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

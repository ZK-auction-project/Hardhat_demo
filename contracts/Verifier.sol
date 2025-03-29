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
        vk.alpha = Pairing.G1Point(uint256(0x13bf2fa72c75ea873dfd83e5071b487239a3b7c82c6b88dc32f97d69e9042ae8), uint256(0x1220d09b1ec1fe2d77ddc9dd7221584dbbbc91acc3790347d64ff4d56a221888));
        vk.beta = Pairing.G2Point([uint256(0x12f15db573bc985b8da8f778a72877700b297da9a14b92a87352b024ee1e3a6b), uint256(0x08daea3370716e17b9ad915f4365cbc92f5d5852a37a8b108299e5236058e1da)], [uint256(0x025bcd4d40b26f828fec9ecec8e7b33719e07ae3bd2e227d18787243664f89a0), uint256(0x295d5fcd5cc42d9d0b47ddcb7f51e85c9ac965c19614f1c6f68d0f95a3af958e)]);
        vk.gamma = Pairing.G2Point([uint256(0x1680e7783ea20221e7ea9ced3548b867ac907d1660ae46e82e69eee40b6d48c8), uint256(0x1b709980fca244aafc6acf3520fe5bca9c863a52b2b966f1ae9878e72fcb04d1)], [uint256(0x290f0e45cc238fd3602ae390ebb15525a1ce98c937ef05babf917d3f5cd734e8), uint256(0x11ad1edc33893b4a8f4e4b199463be8bc709546cce02fabc23807c848b139791)]);
        vk.delta = Pairing.G2Point([uint256(0x02cf747ca1ce63a6aa701d94f951f22acd3ced4b710a7deba40f31e43184783d), uint256(0x04300c82b03888675a91d37ddeb6174ff7478e7d48bff7efd9996554461e2408)], [uint256(0x119b54b757c3000414c572dfb950b54dbae1893730e3896b2434d598ceb45baa), uint256(0x20cc65575147117e7a186868f4dfda97a8f3cb2bffbdf49f97bcdd40fb91e587)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1d5b06ef6d8a31ce71322110e1d68526ed660d33bb5f95d0b036c78e8cc41a69), uint256(0x1d8a2be4b384ad3551d9567f2014585599a013c9701adbeeb7b19d6a428efb3e));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1486594ae5cd02eedcf071660cf8793b0244fd745523990446687f4ac67c265a), uint256(0x2f1217c0fb8ca595313042e360055a57dbdae82de29260d12c40e9d260f90f31));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x20ad71f3bc16cd93b617b7ea519e35e797e716bef8a88e6c97dd31c4f1c2092e), uint256(0x068eaf5b4b5d9c3cf4ac6e1249652c59189f54d1771f7c73cf062f61a864058a));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x00b9c8e76d7967d95f61241255acab59432647bc1a122d1ba788421febfe5472), uint256(0x1e5beb17ede9665d62729d0e80ce1feefa0660afb3bde38d5754349c876b2817));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x01574161ec28463e51bab56b599f84d201f802f6d7659de801399d31d1e8058a), uint256(0x2f406a596eae24b9532fe3ea9a88ddf23caee9d009e3b60247517f8bfc8254d7));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1973002455eed89489036fedf66e8a3a1cd94baa777515692a4ad37caeae1e0f), uint256(0x0365fb8dd3d3a0f57418e1e5a887d2ba54e58b8aeaa06a323976c68cc6ec1e05));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x006a77f186d65bae3cf69d938ef70dfc54c02656a1fe13b827e8af9a9e15b2f4), uint256(0x06850a77d33388587ad8381a0e09f9c994b379814aa696ea87bc21e3a7519439));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x21e9a1dad60669a32d6cb5dcd69e4c02b732c5330d9acfcb0204fc051ab8e99d), uint256(0x2527a28e15f799d7f3b327a1c476739c7ed9ad0bcd356d78999587c87dd37b45));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2c5de6c00fbf8e854ae506cdc4ba1346737a0927d0202c00c8d46e87ebf7b1a4), uint256(0x209b97dc5fa9760df5b09bdc78197f6bed21c0e1a02a63c817c28cc251e692b1));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2fea1088d267ce5a19c66d7ce6ef55f4b5918cbd838bbad1ee86c1038d64acac), uint256(0x2ec50de45daacfd3c99817afd76ca32e20c9e1f237f826b3e589e5201592303d));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0405db6a89007db7ed87fa5a49c25e1dbd74dca0b952f71cf9952effa712b067), uint256(0x0b310e1e1f9e4860a440e529b6386fcb51bd2bc6de3ce8d8873af820b3074872));
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
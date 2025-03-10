// This file is MIT Licensed.
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

contract Verifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x1e92b7f820f94ad6d77c62ab20463b696f21789113e64021738b742513d2cfd9), uint256(0x172f04ea0ce740223aebf5eb66e82ddd226aaed17893b7268ad3c013cce0a8cf));
        vk.beta = Pairing.G2Point([uint256(0x23346e4b05d8f0d72e4a4c596333769cd96b79b01c62eee6af40aee6b1ade574), uint256(0x2368c59d14a2b1a00d5f1642c61a2bc2a53099367ad30bcca57e545a2e59c260)], [uint256(0x1679476cb26f7d9c2f461106bb9f42536bc3244490217223540b3c7bcff1f2e7), uint256(0x2b10cca6fd7d095fe31d0fa9d351f702ce717558f1b247bf34a98082c17ed0b1)]);
        vk.gamma = Pairing.G2Point([uint256(0x0b22a6e8f44cbd3b569af0d2f692ad0e6c45ebfa889b2479d5bbc6e6baf2308c), uint256(0x07e54bc12be45531fa14d48521ba7808f9f345980d77d1a23abf574ba88232ad)], [uint256(0x2fd22951e39ea17e9338112dc3c61df80ea0519f4f51b6396c86c794d45c09a3), uint256(0x1ef03cb84caca329be9faf40311c42415cbd224fcc9261633d90bcd8f26c5421)]);
        vk.delta = Pairing.G2Point([uint256(0x165c149841bc559ab29d35d6f28a05bd903bb870270156040be22db1282f6375), uint256(0x206107605b106b6f94891cd67885297db62dccc928b913f4c57217d88b59705f)], [uint256(0x2ad6aab48e07332dbb6107da9f6d43d2618e4b786623ebfa435ec856c87beba2), uint256(0x06ce91b496a25d8e561b3bc2a95e8a9637ded775971678f7a4258b992293004c)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0cd706b735a17c36f4c0f5f2803d70bc7f5545e931f7b8fbef2a62e691cd3487), uint256(0x2d3f4f2e4fe9df40800f0dfbf85f0848497e30fb41be94902b5839df6aa22a33));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0198653a7f6fa200dabc124c8cc8a8059b4851882a5b7d173c64a8deefaaabec), uint256(0x1469a3cf33a2293e8e66ea644d4608dff5a284aace51081157ec05def6bc6cf6));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x00e961879a0b2683f5275afc78818aca68440ae93bbad9a389f7a6bd805c3617), uint256(0x279a95230bf59268eb66d872b3c0428c487cd67672fc66185a71f5d6e1148953));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x304776052ded7cd9315b1b56f34bd7f78c3ead6203367bb52435ae22de731b23), uint256(0x0a7656394634215e686501a984e95a094f6c971f4c1865e04c5ff5c9711ed1c0));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2e1a18bd5bbaa323348362bd9f2c8fc86e27efd33e32273198a412d35716ba2a), uint256(0x0deb75790d344a2cd12fb609abb33183c65d7c624c2c2bda5f32604839a54fb9));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x064b627244a56183a434fefaad18ac6da142dd96b6457973e5ae00fddde85cc7), uint256(0x166d030a8a6b4bacd526008959997d3e976f30ae7e9620d704a0f4edca3b4085));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2a85eba05fbed1a95c49dd5f48bb1d69f786b84a45579ad379937253b6a8ebb9), uint256(0x2366ea802cf897cefb5320ad052d6c06f27979d2bb69d5b41525c66c97608ab1));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x095ba2734c49be8f6f3512cae418ee3c2e057a09e13add7d8cc36c095d338124), uint256(0x0499f778c62d270031ca36a48a481e1e0e98521a78b9402161c126dcb3772f77));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2d6ef9679f1a2636aa452b57ea74eed90ee614bb9b19d7e15e02a9edb68a031f), uint256(0x134c17f83cf0666d40f91e3e22ee072658a2fac99d2bbcdc58930e61f7d7bb15));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0f91b38f00549bda3155ac78a45433dc08bfc7d5b655adddc204ae3b52d60610), uint256(0x1ba6e2cd8d63491e5844cedfb9a4d95808fb203968d1cc7fabb0a71bb55c5280));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x070a044e7d1ef47efe63e367473d02864393e8e2cbe904f3539c62bad3800818), uint256(0x0260a4f2c3329ab063e90de75e2533c124af6aa5209942506cfc3264a7095884));
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

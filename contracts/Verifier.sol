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
        vk.alpha = Pairing.G1Point(uint256(0x2103c49dfbbfd75835bd9545c546deeb4d484282209870b423441e396f248903), uint256(0x0acc8dc568225efeb90e68dc7fac135397e370399c6a14b5c1448cd6e5b3bd7d));
        vk.beta = Pairing.G2Point([uint256(0x01cce8e79f46158677ee04b012991f4f9905595b3ea3e92eca013e28ae24d823), uint256(0x0aad384a12a4bf146e83259f463a5e4e31e860dce31fb9623d52b9f22e0591ef)], [uint256(0x1c99c1402ce6533f34d3e90e8a345caa969fbae79b324af288f2ae4d94e1ff1a), uint256(0x23fe642170f9bfd3bb1e3eff627e9b6705cad78374c2c267484f5a9f748f2084)]);
        vk.gamma = Pairing.G2Point([uint256(0x207c69ca95c839722f5ac036debdbb138362f9107dad7d54ca6c20baf7bd5a06), uint256(0x20fc81c7d2fdab054893b9e06834f8607c9fb6f2f381a07177807691735f1b2c)], [uint256(0x20f59c1993fd07ee0f1109b0ad6a37684d1134354dacd7684511b0e57e916b1d), uint256(0x003c09af152e35bbe891d86c65f82fa0f9ecafe358e2b7b8e17460ae76f05200)]);
        vk.delta = Pairing.G2Point([uint256(0x1d7ba30a4ebef135b355a093821115c9908b1be753a2807aa9a0648f839cd58d), uint256(0x07874b5e74810777c62494ecf5d75692330b0449713da990c4dfb4edb39ae038)], [uint256(0x236562dd50d6a33edadc1f48a19b6cd183e916e02b89210c0b5bcca7c4baa64b), uint256(0x03e47bb2a8feef5dc76ea8832797bb697aa7e62639ecd5affcebbbddb00a5d72)]);
        vk.gamma_abc = new Pairing.G1Point[](2);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1835793dcfbe20bcae26b9514af76df30ebed631ba61687063cc004061ee666c), uint256(0x0058b7aa8eee4cef99703e68b5198b1a1c5d6902be988ef9ccb52547f3b53446));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x222e523c26fd396216385cdbfafb5c39a8e3de602258d4d3e0acb59653a3ce5f), uint256(0x2515fd0d74f41b650cf8aba947cb8ae72280893f68b16adbf0fc8d99a37216fd));
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
        vk.alpha = Pairing.G1Point(uint256(0x0746b9e67f45869fc6022851032452b089918cdc480cfd08b08cdee903375b77), uint256(0x0ab387081014269c3b0bfd922f02154a35cffe0f2978b36268fcd4dd291a3d33));
        vk.beta = Pairing.G2Point([uint256(0x196b1945a3c94f98860ac2670ce6a5b41551950772900663ea75b35394f239ca), uint256(0x2e34f8b1f57af7fdf0898c69937b3553672a6e957799b50c5414b75e13f5eb11)], [uint256(0x03fd726fd7eb43b4e870821a5cdead365d4b16f1ef43dede1ab0c35c51cd84af), uint256(0x12b7fb0e250070be7a383c68a2c7d5412951d370716618e885b4d5782d0738c4)]);
        vk.gamma = Pairing.G2Point([uint256(0x259b5455cd840b7f54689c57398fb9c61c0871cc44e70d031bb7f80ed83f7b6a), uint256(0x1e4c35f343a2e787e2876a8a9410c110efb64685de901de2a39df9a068054500)], [uint256(0x21097e90f6f057066e32f313c3a1c22109b0c0a49c344acd5034a8be2b302bec), uint256(0x043f7959b196dcad396a3c3e2478fa2439b9f6b01864a1fb67c210cc3c0ba810)]);
        vk.delta = Pairing.G2Point([uint256(0x2881f70c18abfebc25cc2036067f634b9f33060fc905ba13ccce3eaf4ad7c4e8), uint256(0x02b22ad140aa5c33907b57013a6e835daf0a269199f94d8b49d7628b9d9da875)], [uint256(0x0a5b3ac9a088d1dd40a6b8e1186a70975819935d5ed7c0816b804f091fbf1950), uint256(0x1a7939e95369722162f03f4f68197976d0705ab13f410d5b63b16be49ab98744)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1f6662fc59e5ff9e380f2bcccbc508194696d5d171214529e78e3391e000dd04), uint256(0x0d039fc7c7317dfe61230305cd08ca7c53fc922c0c92685734b4575b70ba3cd1));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x25a785e604853183356ff376c22d583ccaa2e2f9523b6d27f78660cf73d12139), uint256(0x1782c579c9890134f784faeb3194e993e054563f627539d3d78aed102abe7664));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x1600e5bd4de9823c0e3830855426f99ea020984534e6cab80ca078db12e024ff), uint256(0x059ef57464cb7ce5109fde462a9caecf1e9722f2f6f230abb09cfb93ee07b25a));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x169319924774d3f741c563bfc3654ff9a1b465a10c669ae3a0ee631187f9d0ef), uint256(0x10ccd00b16bc13a12d71bcc6e41bded4db04413b6ba0198fe3cc908cf8c0e32c));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x254717302a2972b108b2fc990f8f93cf579f7f13642e23d3153d9869465e9675), uint256(0x15bccc62bd6cc38e494a03ecf20d0b0563af7d810db78ad5d43aa5d0313256f4));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1b355b8e8dc2f121a34f4161933aa76c23c29b676846b5ce6d2ec5ab2d05e593), uint256(0x113be18dacfdc210f5f9e60a7088c67e63840e024dffd03102e6b9f817d20716));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2adf9e10e59d35132415ddb0f34cc3516191688ad133b96d89fd79d77a52b443), uint256(0x185ead86541328a8104743a67d1b403fbd7f1ed741e69ca8748dd3b67c39d8ac));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x20a62ba06e499d0c54f7f9b3fabe570c6c5dd6287e684df08460181ea124b707), uint256(0x02bea95fde81ccb4a4b7d500d8203cedc682dc8476cc97e55bbcaf87ed5cfa16));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2aa058446a78490e5945d7c10b6ad51987ef42dfdb3c1e4b3aba56c849d9c8dd), uint256(0x1a712e549c056f399fd7c31758aea81df889d98688f71cd4fdb8217b7a70aab2));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0297ff7c49d10c5ed9d6cedb666b3c7536d1250b954963d6f2970002922af03c), uint256(0x0010e3fa249c743692a72b21fdd7237ba1646f775fc3d3976c1bcb400e51b602));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x01f5b9a28e22b055ef560b3b5de0fc4dcd4cd3a817ef8635c5192e9c4ce50bab), uint256(0x04008772be01d56f70f82978600bf626f39e0967f93e6cdbb0f3aec96f89d4a7));
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

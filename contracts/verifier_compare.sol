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
        vk.alpha = Pairing.G1Point(uint256(0x167cf88f0c131398dcec3311096ba16381869ea3e45b4f631a618784ede9ad36), uint256(0x2c3b3f92b52b96c816b90eec126561aec10e10e54900a78ce687e8c09c7e72ba));
        vk.beta = Pairing.G2Point([uint256(0x1aad7ca44b4263f509a7d5de388dc6ec68077c500ab7f112e952bafe008ca59c), uint256(0x12ff089496ba616a6ce59ed10d889c1ab42c968c3e174490a510e777399ae9cf)], [uint256(0x0d2a56dd0101fa17ddf4514105d26e7b2d51d8a6eb4ec50f0414d3f10c8b97d4), uint256(0x136056d52d198784ef4a9e63c878474e8afe5ce88d81803302b8de4908043a15)]);
        vk.gamma = Pairing.G2Point([uint256(0x18476bd7540fb41d2eb877cf722cd6feec63f906367f5ee70c92db2e51dd2e9a), uint256(0x03537ff3cf245c81d6c4d770ff23be8b0e5b52b1629bcaa228ec5759073369f0)], [uint256(0x0a64a359bd2cc9cf3961255052d60a35d56659887081771994ec5806f65f8cfc), uint256(0x0209a6c731d2b1a66c9f7e491ddea869bacf66aa22e8074ea0da502f41c01de9)]);
        vk.delta = Pairing.G2Point([uint256(0x1565c325a8a406ad80a42a76616a0db00e21f7e71031a1bfe9baf8aa0fd11265), uint256(0x1ac339f225df5f4c4c64ba11e118e891156b80fc8552879e2d3a16bc42c7bd02)], [uint256(0x2019565483cf4f013c0bfcd4fe484b1cb5749586eed852820495ccf876485430), uint256(0x19242603dd59098dc4219964a25dc99328d443deab27427f0134ac43a4fbfd3b)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1b78b8acca939b6c54a8e1271512073d5044c2b27cc8e5d15e4e55cc4be888bb), uint256(0x104a1ec57e86fd0207d05d74d20c91c6fea5e03fcfa8dfe27f8d15939d902b8b));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0d53340d46980b3f85bc19da581bfb0eb4c227caf9d91ee588084fb6ff07cbb8), uint256(0x2ede24683de1de7c1e1536af400969bb10c858a9908bccc6bacb1ad03681ccf0));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2f5dbaabf5d173fd0682e756ed9f672a97db10cfac46511426186327e11a1c64), uint256(0x0897fd15e4a05e4b0ba6791008226daac64753aa0dccd486758e5284083fd985));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x282a7c2275ae137d2fb5b0d43c4d51078fb4d1163d9948eeb7f3df8570ce8e26), uint256(0x132e700b1e8b3cf82a2be48d57335ce85d0eabfae61304ba9413d1e18a5e0d5d));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1eacaba315626f2d87ea4cfe32165cda4a4cfdb3c2f89f46af60b9edda5ed279), uint256(0x1778b08d2973520fff2f0f993cfced0a3df78197ef7ccb40b72186ca8b54046f));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0b2c114e7f2e94af914478aa2eb19dd34b2ae620d1978b90baf190b69b13f175), uint256(0x288c9dba8585d8616fa16b6ffd3c0ae3d4e182d50f6399f8e6b43176b8e755e4));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2656f13136767e6f5e23efa8b2b4aeb35d91d347f1cd3c8d768585d1d7aa81f1), uint256(0x0db272da33a63c3db24d059073b91034bacf65db3ebd7081c3ddf563ed5f9016));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x182997e129020b53ac352aa1864b4f75be876437625a812724e0924f39f7a773), uint256(0x26241b59a48556494e40700e46575ead014c8fd2f105030c60f55cd0a7d48e11));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x29707c9eb3de8be5e62d24cae2de475ac16ded42e28ef7d9d38b137067be752a), uint256(0x0ce8ee2d2e8299bfd650a67b6d5894a44a53984852508a1fbdb614dfc0466457));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2a915fa2d160f3eaa5959bd777dd7228fb54ebcdd8c8ebfb12b5e9e81be30324), uint256(0x1b5efe23c7309e30a44fc9485c9b69431cd9dc3ffc4a12901478c2b46479ddc4));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x09a0c77e9b2e70612fa0998dacf19cc443a751371efddd364d9c6d569d9bcfbc), uint256(0x157aac74fada0156f157d57a35e834451047e6bfb9d7cdbb44025285f58be891));
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

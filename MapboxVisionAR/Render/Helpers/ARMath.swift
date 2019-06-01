// swiftlint:disable comma identifier_name operator_usage_whitespace
// swiftformat:disable indent spaceInsideParens

import simd

extension float4 {
    var xyz: float3 {
        return float3(x, y, z)
    }
}

extension simd_quatf {
    var rotMatrix: float3x3 {
        let x = self.vector[0]
        let y = self.vector[1]
        let z = self.vector[2]
        let w = self.vector[3]

        let fTx  = x + x
        let fTy  = y + y
        let fTz  = z + z
        let fTwx = fTx * w
        let fTwy = fTy * w
        let fTwz = fTz * w
        let fTxx = fTx * x
        let fTxy = fTy * x
        let fTxz = fTz * x
        let fTyy = fTy * y
        let fTyz = fTz * y
        let fTzz = fTz * z

        var kRot = matrix_identity_float3x3
        kRot[0][0] = 1.0 - (fTyy + fTzz)
        kRot[0][1] = fTxy - fTwz
        kRot[0][2] = fTxz + fTwy
        kRot[1][0] = fTxy + fTwz
        kRot[1][1] = 1.0 - (fTxx + fTzz)
        kRot[1][2] = fTyz - fTwx
        kRot[2][0] = fTxz - fTwy
        kRot[2][1] = fTyz + fTwx
        kRot[2][2] = 1.0 - (fTxx + fTyy)

        return kRot
    }

    static func byAxis(_ xRadians: Float, _ yRadians: Float, _ zRadians: Float) -> simd_quatf {
        return simd_quatf(angle: xRadians, axis: float3(1, 0, 0)) *
               simd_quatf(angle: yRadians, axis: float3(0, 1, 0)) *
               simd_quatf(angle: zRadians, axis: float3(0, 0, 1))
    }
}

func makeTransformMatrix(trans: float3, rot: simd_quatf, scale: float3) -> float4x4 {
    let rot3x3 = rot.rotMatrix

    return float4x4(float4(rot3x3[0][0] * scale.x, rot3x3[1][0] * scale.y, rot3x3[2][0] * scale.z, 0),
                    float4(rot3x3[0][1] * scale.x, rot3x3[1][1] * scale.y, rot3x3[2][1] * scale.z, 0),
                    float4(rot3x3[0][2] * scale.x, rot3x3[1][2] * scale.y, rot3x3[2][2] * scale.z, 0),
                    float4(trans[0],               trans[1],               trans[2], 1))
}

func makeViewMatrix(trans: float3, rot: simd_quatf) -> float4x4 {
    let rot3x3 = rot.rotMatrix

    // Make the translation relative to new axes
    let rotT = rot3x3.transpose
    let t = -rotT * trans

    return float4x4(float4(rotT[0][0], rotT[1][0], rotT[2][0], 0),
                    float4(rotT[0][1], rotT[1][1], rotT[2][1], 0),
                    float4(rotT[0][2], rotT[1][2], rotT[2][2], 0),
                    float4(t[0],       t[1],       t[2],       1))
}

func makePerpectiveProjectionMatrix(fovRadians: Float, aspectRatio aspect: Float, nearZ: Float, farZ: Float) -> float4x4 {
    let yScale = 1 / tan(fovRadians * 0.5)
    let xScale = yScale / aspect
    let zRange = nearZ - farZ
    let zScale = (farZ + nearZ) / zRange
    let wzScale = 2 * farZ * nearZ / zRange

    return float4x4(float4(xScale,  0,      0,          0),
                    float4( 0,      yScale, 0,          0),
                    float4( 0,      0,      zScale,     -1),
                    float4( 0,      0,      wzScale,    1))
}

func normalMatrix(mat: float4x4) -> float3x3 {
    let upperLeft = float3x3(mat[0].xyz, mat[1].xyz, mat[2].xyz)
    return upperLeft.transpose.inverse
}

func degreesToRadians(_ degrees: Float) -> Float {
    return degrees * .pi / 180
}

func radiansToDegrees(_ radians: Float) -> Float {
    return radians * 180 / .pi
}

Shader "Unlit/Water Depth"
{
    Properties
    { 
        _DeepColor ("Deep Color", Color) = (0,0,0,0)
        _SurfaceColor ("Surface Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        ZWrite Off
        LOD 100
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;
            float4 _DeepColor;
            float4 _SurfaceColor;

            struct VertexInput
            {
                float4 vertex : POSITION;
                // float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 screenPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 depth : TEXCOORD1;
            };


            Interpolators vert (VertexInput v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                UNITY_TRANSFER_DEPTH(o.depth);

                // Get uvs based on screen position
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                // Get the screen uvs by normalising the screen position (make w = 1, 4D -> 3D)
                float2 uvScreen = i.screenPos.xy / i.screenPos.w;

                // Get the depth from the depth texture using the screenpos uv
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uvScreen);
                // Since the depth texture from a perspective camera is non linear, it needs to be converted to linear:
                // Get the eye/view space depth (remove camera perspective)
                float sceneDepth = LinearEyeDepth(depth);

                // i.screenPos.w is the view space depth
                float waterDepth = (sceneDepth-i.screenPos.w);
                return lerp(_SurfaceColor, _DeepColor, waterDepth*0.5);

            }
            ENDCG
        }
    }
}

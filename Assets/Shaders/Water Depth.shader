Shader "Unlit/Water Depth"
{
    Properties
    { 
        _DeepColor ("Deep Color", Color) = (0,0,0,0)
        _SurfaceColor ("Surface Color", Color) = (1,1,1,1)
        _DepthScale ("Depth Scale", Range(0,1)) = 1
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamPercent ("Foam Percentage", Range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        ZWrite Off
        Cull Front
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _DeepColor;
            float4 _SurfaceColor;
            float _DepthScale;

            float4 _FoamColor;
            float _FoamPercent;

            // Get the depth texture from the camera
            sampler2D _CameraDepthTexture;

            struct VertexInput
            {
                float4 vertex : POSITION;
            };

            struct Interpolators
            {
                float4 screenPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Interpolators vert (VertexInput v)
            {
                Interpolators o;
                // Make the water move up and down. 0.05 scales by how much the water moves up and down
                v.vertex += sin(_Time.y) * 0.05;

                o.vertex = UnityObjectToClipPos(v.vertex);

                // Get uvs based on screen position. 
                // This is a 4D vector where the alpha component contains the view space depth (distance to surface)
                o.screenPos = ComputeScreenPos(o.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                // Get the screen uvs by normalising the screen position (make w = 1, 4D -> 3D)
                float2 uvScreen = i.screenPos.xy / i.screenPos.w;
                // Get the depth from the depth texture using the screenpos uv
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uvScreen);
                // The depth is non-linear, as it has more details up close.
                // This changes it to be linear
                float sceneDepth = LinearEyeDepth(depth);

                // i.screenPos.w is the view space depth (distance to surface). 
                // Subtract it from the scene depth (distance to bottom of water) to get the depth of the water from the camera's perspective
                float waterDepth = (sceneDepth-i.screenPos.w);
                // Scale the depth and clamp it between 0 and 1
                waterDepth = saturate(waterDepth*_DepthScale);
                
                // Use the depth in a lerp to interpolate between the surface color and deep color
                float4 depthGradient = lerp(_SurfaceColor, _DeepColor, waterDepth);

                // Make a mask for the foam as a percentage of the water depth
                float foamMask = waterDepth < _FoamPercent;
                // Apply the foam mask
                float4 foam = foamMask * _FoamColor;
                // Apply the inverse of the foam mask to stop the water and foam from blending
                depthGradient *= (1-foamMask);

                // Output the water depth with foam added
                return depthGradient + foam;
            }
            ENDCG
            
        }


        // When under the water
        Cull Back
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _DeepColor;
            float4 _SurfaceColor;
            float _DepthScale;

            struct VertexInput
            {
                float4 vertex : POSITION;
            };

            struct Interpolators
            {
                float4 screenPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Interpolators vert (VertexInput v)
            {
                Interpolators o;
                // Make the water move up and down
                v.vertex += sin(_Time) * 0.05;
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Get uvs based on screen position
                o.screenPos = ComputeScreenPos(o.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                // Scale the distance to the surface and clamp it between 0 and 1
                float waterDepth = saturate(i.screenPos.w*_DepthScale);
                
                // Use the depth in a lerp to interpolate between the surface color and deep color
                float4 depthGradient = lerp(_SurfaceColor, _DeepColor, waterDepth);

                // Output the water depth
                return depthGradient;
            }
            ENDCG
        }
    }
}

Shader "Custom/PreIntegratedSkinLUT"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _ScatteringLUT("Scattering Lookup Table", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardWithPreIntegratedSkin fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
		
		struct SurfaceOutputStandard2
		{
			    fixed3 Albedo;      // base (diffuse or specular) color
				float3 Normal;      // tangent space normal, if written
				half3 Emission;
				half Metallic;      // 0=non-metal, 1=metal
				// Smoothness is the user facing name, it should be perceptual smoothness but user should not have to deal with it.
				// Everywhere in the code you meet smoothness it is perceptual smoothness
				half Smoothness;    // 0=rough, 1=smooth
				half Occlusion;     // occlusion (default 1)
				fixed Alpha;        // alpha for transparencies
				
				float3 worldPos;
		};

        #include "UnityPBSLighting.cginc"

        sampler2D _MainTex;
        sampler2D _ScatteringLUT;

        struct Input
        {
            float2 uv_MainTex;
			float3 worldPos; // 号称会自动填充这个值？
        };

        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        inline half4 LightingStandardWithPreIntegratedSkin(SurfaceOutputStandard2 s, half3 viewDir, UnityGI gi)
        {
			SurfaceOutputStandard tmp;
			tmp.Albedo = s.Albedo;
			tmp.Normal = s.Normal;
			tmp.Emission = s.Emission;
			tmp.Metallic = s.Metallic;
			tmp.Smoothness = s.Smoothness;
			tmp.Occlusion = s.Occlusion;
			tmp.Alpha = s.Alpha;
		
            half4 lighting = LightingStandard(tmp, viewDir, gi);
            half wrappedNdL = (dot(gi.light.dir, s.Normal) * 0.5 + 0.5);
			
			float curvity = length ( fwidth (s.Normal ) ) / length ( fwidth (s.worldPos ) );
			curvity = saturate(curvity);

            half4 scatteringColor = tex2D(_ScatteringLUT, float2(wrappedNdL, 1));
            lighting.rgb +=  gi.light.color * s.Albedo * scatteringColor.rgb ;
			
			//if(curvity >= 1)
			//{
			//	return half4(s.worldPos, 1);
			//}
            return lighting;
        }

        inline void LightingStandardWithPreIntegratedSkin_GI(inout SurfaceOutputStandard2 s, UnityGIInput data, inout UnityGI gi)
        {
            //half shadow = data.atten;
			SurfaceOutputStandard tmp;
			tmp.Albedo = s.Albedo;
			tmp.Normal = s.Normal;
			tmp.Emission = s.Emission;
			tmp.Metallic = s.Metallic;
			tmp.Smoothness = s.Smoothness;
			tmp.Occlusion = s.Occlusion;
			tmp.Alpha = s.Alpha;
			
            LightingStandard_GI(tmp, data, gi);
			
			s.Albedo = tmp.Albedo;
			s.Normal = tmp.Normal;
			s.Emission = tmp.Emission;
			s.Metallic = tmp.Metallic;
			s.Smoothness = tmp.Smoothness;
			s.Occlusion = tmp.Occlusion;
			s.Alpha = tmp.Alpha;
			
            //gi.light.ndotl = shadow;
        }

        void surf (Input IN, inout SurfaceOutputStandard2 o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;

            // Metallic and smoothness come
            o.Metallic = 0;
            o.Smoothness = 0.5;
            o.Alpha = c.a;
			o.worldPos = IN.worldPos;
        }
        ENDCG
    }
    FallBack "Diffuse"
}

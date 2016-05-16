// Converts source rgb into yuv. A copy of the y value is put in the output alpha. By -Vit-
//!HOOK SCALED
//!BIND HOOKED
//!COMPONENTS 4

#define to_gamma	//comment out (and on line 166) if input light is already in gamma space

#define Src(a,b) HOOKED_texOff(vec2(a,b))

#define RGBtoYUV(Kb,Kr) mat3(vec3(Kr, 1.0 - Kr - Kb, Kb), vec3(-Kr, Kr + Kb - 1.0, 1.0 - Kb) / (2.0*(1.0 - Kb)), vec3(1.0 - Kr, Kr + Kb - 1.0, -Kb) / (2.0*(1.0 - Kr)))

#define Gamma(x)  ( mix(x * vec3(12.92), vec3(1.055) * pow(max(x, 0.0), vec3(1.0/2.4)) - vec3(0.055), step(vec3(0.0031308), x)) )

vec4 hook() {
	vec3 c = Src(0,0).rgb;
	#ifdef to_gamma
		c = Gamma(c);
	#endif
	vec3 yuv = c * ( HOOKED_size.y <= 576.0 ? RGBtoYUV(0.114,0.299) : RGBtoYUV(0.0722,0.2126))+vec3(0.0,0.5,0.5);
	return vec4(yuv,yuv.x);
}

//!HOOK SCALED
//!BIND HOOKED
// RemoveGrain(11,-1) equivalent by -Vit-

#define Src(a,b) HOOKED_texOff(vec2(a,b))

vec4 hook() {
	vec4 o = Src(0,0);
	
	o.x += o.x;
	o.x += Src( 0,-1).x+Src(-1, 0).x+Src( 1, 0).x+Src( 0, 1).x;
	o.x += o.x;
	o.x += Src(-1,-1).x+Src( 1,-1).x+Src(-1, 1).x+Src( 1, 1).x;
	o.x *= 0.0625f;

	return o;
}

//!HOOK SCALED
//!BIND HOOKED
// RemoveGrain(4,-1) equivalent by -Vit-

#define Src(a,b) HOOKED_texOff(vec2(a,b))

// The variables passed to these median macros will be swapped around as part of the process. A temporary variable t of the same type is also required.
#define sort(a1,a2)                         (t=min(a1,a2),a2=max(a1,a2),a1=t)
#define median3(a1,a2,a3)                   (sort(a2,a3),sort(a1,a2),min(a2,a3))
#define median5(a1,a2,a3,a4,a5)             (sort(a1,a2),sort(a3,a4),sort(a1,a3),sort(a2,a4),median3(a2,a3,a5))
#define median9(a1,a2,a3,a4,a5,a6,a7,a8,a9) (sort(a1,a2),sort(a3,a4),sort(a5,a6),sort(a7,a8),\
                                             sort(a1,a3),sort(a5,a7),sort(a1,a5),sort(a3,a5),sort(a3,a7),\
                                             sort(a2,a4),sort(a6,a8),sort(a4,a8),sort(a4,a6),sort(a2,a6),median5(a2,a4,a5,a7,a9))

vec4 hook() {
	vec4 o = Src(0,0);

	float t;
	float t1 = Src(-1,-1).x;
	float t2 = Src( 0,-1).x;
	float t3 = Src( 1,-1).x;
	float t4 = Src(-1, 0).x;
	float t5 = o.x;
	float t6 = Src( 1, 0).x;
	float t7 = Src(-1, 1).x;
	float t8 = Src( 0, 1).x;
	float t9 = Src( 1, 1).x;
	o.x = median9(t1,t2,t3,t4,t5,t6,t7,t8,t9);
	
	return o;
}

//!HOOK SCALED
//!BIND HOOKED
// FineSharp by Didйe. Part A

#define antiring 0.0
#define sstr 2.0   // Strength of sharpening, 0.0 up to 8.0 or more. If you change this, then alter cstr below
#define cstr 0.9   // Strength of equalisation, 0.0 to 2.0 or more. Suggested settings for cstr based on sstr value (if antiring is 0): 
                   // sstr=0->cstr=0, sstr=0.5->cstr=0.1, 1.0->0.6, 2.0->0.9, 2.5->1.00, 3.0->1.09, 3.5->1.15, 4.0->1.19, 8.0->1.249, 255.0->1.5
#define lstr 1.49  // Modifier for non-linear sharpening
#define pstr 1.272 // Exponent for non-linear sharpening
#define ldmp (sstr+0.1f) // "Low damp", to not over-enhance very small differences (noise coming out of flat areas)

// To use the "mode" setting in original you must change shaders earlier in chain: mode=1->RG11 RG4, mode=2->RG4 RG11, mode=3->RG4 RG11 RG4
// Negative modes are not supported
// XSharpen settings are in Part C

#define Src(a,b) HOOKED_texOff(vec2(a,b))
#define SharpDiff(c) (t=c.a-c.x, sign(t) * (sstr/255.0f) * pow(abs(t)/(lstr/255.0f),1.0f/pstr)* ((t*t)/(t*t+ldmp/(255.0f*255.0f))))

vec4 hook() {
    vec4 o = Src(0,0);
    vec4 x1 = Src(0,-1);
    vec4 x2 = Src(-1,0);
    vec4 x3 = Src(1,0);
    vec4 x4 = Src(0,1);
    vec4 x5 = Src(-1, -1);
    vec4 x6 = Src( 1,-1);
    vec4 x7 = Src(-1, 1);
    vec4 x8 = Src( 1, 1);
    float t;
    float sd = SharpDiff(o);
    float low = min(min(min(min(x1.x,x2.x),min(x3.x,x4.x)),min(min(x5.x,x6.x),min(x7.x,x8.x))),o.x);
    float hi  = max(max(max(max(x1.x,x2.x),max(x3.x,x4.x)),max(max(x5.x,x6.x),max(x7.x,x8.x))),o.x);
    o.x = o.a + sd;
    sd += sd;
    sd += SharpDiff(x1) + SharpDiff(x2) + SharpDiff(x3) + SharpDiff(x4);
    sd += sd;
    sd += SharpDiff(x5) + SharpDiff(x6) + SharpDiff(x7) + SharpDiff(x8);
    sd *= 0.0625f;
    o.x = mix(o.x, clamp(o.x, low, hi), antiring);
    o.x -= cstr * sd;
    o.a = o.x;

    return o;
}

//!HOOK SCALED
//!BIND HOOKED
// FineSharp by Didйe. Part B

#define Src(a,b) HOOKED_texOff(vec2(a,b))

// The variables passed to these sorting macros will be swapped around as part of the process. A temporary variable t of the same type is also required.
#define sort(a1,a2)                               (t=min(a1,a2),a2=max(a1,a2),a1=t)
#define sort_min_max3(a1,a2,a3)                   (sort(a1,a2),sort(a1,a3),sort(a2,a3))
#define sort_min_max5(a1,a2,a3,a4,a5)             (sort(a1,a2),sort(a3,a4),sort(a1,a3),sort(a2,a4),sort(a1,a5),sort(a4,a5))
#define sort_min_max7(a1,a2,a3,a4,a5,a6,a7)       (sort(a1,a2),sort(a3,a4),sort(a5,a6),sort(a1,a3),sort(a1,a5),sort(a2,a6),sort(a4,a5),sort(a1,a7),sort(a6,a7))
#define sort_min_max9(a1,a2,a3,a4,a5,a6,a7,a8,a9) (sort(a1,a2),sort(a3,a4),sort(a5,a6),sort(a7,a8),sort(a1,a3),sort(a5,a7),sort(a1,a5),sort(a2,a4),sort(a6,a7),sort(a4,a8),sort(a1,a9),sort(a8,a9))
// sort9_partial1 only sorts the min and max into place (at the ends), sort9_partial2 sorts the top two max and min values, etc. Used for avisynth "Repair" script equivalent 
#define sort9_partial1(a1,a2,a3,a4,a5,a6,a7,a8,a9) (sort_min_max9(a1,a2,a3,a4,a5,a6,a7,a8,a9))
#define sort9_partial2(a1,a2,a3,a4,a5,a6,a7,a8,a9) (sort_min_max9(a1,a2,a3,a4,a5,a6,a7,a8,a9),sort_min_max7(a2,a3,a4,a5,a6,a7,a8))
#define sort9_partial3(a1,a2,a3,a4,a5,a6,a7,a8,a9) (sort_min_max9(a1,a2,a3,a4,a5,a6,a7,a8,a9),sort_min_max7(a2,a3,a4,a5,a6,a7,a8),sort_min_max5(a3,a4,a5,a6,a7))
#define sort9(a1,a2,a3,a4,a5,a6,a7,a8,a9)          (sort_min_max9(a1,a2,a3,a4,a5,a6,a7,a8,a9),sort_min_max7(a2,a3,a4,a5,a6,a7,a8),sort_min_max5(a3,a4,a5,a6,a7),sort_min_max3(a4,a5,a6))

vec4 hook() {
	vec4 o = Src(0,0);

	float t;
	float t1 = Src(-1,-1).a;
	float t2 = Src( 0,-1).a;
	float t3 = Src( 1,-1).a;
	float t4 = Src(-1, 0).a;
	float t5 = o.a;
	float t6 = Src( 1, 0).a;
	float t7 = Src(-1, 1).a;
	float t8 = Src( 0, 1).a;
	float t9 = Src( 1, 1).a;

	o.x += t1+t2+t3+t4+t6+t7+t8+t9;
	o.x /= 9.0f;
	o.x = o.a + 9.9f*(o.a-o.x);
	
	sort9_partial2(t1,t2,t3,t4,t5,t6,t7,t8,t9);
	o.x = max(o.x,min(t2,o.a));
	o.x = min(o.x,max(t8,o.a));

	return o;
}

//!HOOK SCALED
//!BIND HOOKED
// FineSharp by Didйe. Part C

#define to_gamma

#define xstr 0.19 // Strength of XSharpen-style final sharpening, 0.0 to 1.0 (but, better don't go beyond 0.249 ...)
#define xrep 1.0 // Repair artefacts from final sharpening, 0.0 to 1.0 or more (-Vit- addition to original script)

#define Src(a,b) HOOKED_texOff(vec2(a,b))

#define YUVtoRGB(Kb,Kr) mat3(vec3(1, 0, 2.0*(1.0 - Kr)), vec3(Kb + Kr - 1.0, 2.0*(1.0 - Kb)*Kb, 2.0*Kr*(1.0 - Kr)) / (Kb + Kr - 1.0), vec3(1, 2.0*(1.0 - Kb),0))

#define GammaInv(x) ( mix(pow((x + vec3(0.055))/vec3(1.055), vec3(2.4)), x / vec3(12.92), step(x, vec3(0.04045))) )

vec4 hook() {
	vec4 o = Src(0,0);

	float edge = abs(Src(0,-1).x+Src(-1,0).x+Src(1,0).x+Src(0,1).x - 4.0*o.x);
	o.x = mix(o.a, o.x, xstr*(1.0-clamp(edge*xrep, 0.0, 1.0)));

	o.rgb = (o.xyz-vec3(0.0,0.5,0.5)) * ( HOOKED_size.y <= 576.0 ? YUVtoRGB(0.114,0.299) : YUVtoRGB(0.0722,0.2126)); //ToRGB
	#ifdef to_gamma
		o.rgb = GammaInv(o.rgb);
	#endif
	return o;
}
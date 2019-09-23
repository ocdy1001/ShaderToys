#define MAX_STEPS 100
#define MAX_DIST 1000.
#define EPSILON 0.01
#define AMBIENT 0.05

float raymarch_d(vec3, vec3);
float raymarch_s(vec3, vec3, float);
//https://stackoverflow.com/questions/45597118/fastest-way-to-do-min-max-based-on-specific-component-of-vectors-in-glsl
vec2 minx(vec2 a, vec2 b)
{
    return mix( a, b, step( b.x, a.x ) );
}
//iq's blend functions
float sdfBlendUnion(float d1, float d2, float k){
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}

float sdfBlendSub(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d2, -d1, h) + k*h*(1.0-h);
}

float sdfBlendInter(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) + k*h*(1.0-h);
}

float sphere(vec3 p, vec3 so, float sr){
	return length(p - so) - sr;   
}

float capsule(vec3 p, float h, float r)
{
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float scene_dist(vec3 p){
    float t = iTime;
    float head = sphere(p,vec3(-.9,1,5), .5);
    float eye0 = sphere(p,vec3(-1.3,2.,5.+.3), .2);
    float eye1 = sphere(p,vec3(-1.3,2.,5.-.3), .2);
    float stick0 = capsule(p-vec3(-1.1,1,5.+.3), 1., .05);
    float stick1 = capsule(p-vec3(-1.1,1,5.-.3), 1., .05);
    float c = .9*2.;
    vec3 q = p;
    q.x = mod(max(0.,p.x),c)-0.5*c;
    float body0 = sphere(q,vec3(0,1,5), .6);
    float leg0l = capsule(q-vec3(0,.1,5.+.3), .5, .05);
    float leg0r = capsule(q-vec3(0,.1,5.-.3), .5, .05);
    float foot0l = sphere(q,vec3(-.15,0,5.+.3), .1);
    float foot0r = sphere(q,vec3(-.15,0,5.-.3), .1);
    q.x = mod(max(0.,p.x + 0.9),c)-0.5*c;
    float body1 = sphere(q,vec3(0,1,5), .6);
    float leg1l = capsule(q-vec3(0,.1,5.+.3), .5, .05);
    float leg1r = capsule(q-vec3(0,.1,5.-.3), .5, .05);
    float foot1l = sphere(q,vec3(-.15,0,5.+.3), .1);
    float foot1r = sphere(q,vec3(-.15,0,5.-.3), .1);
    float floord = p.y;
    float d = sdfBlendUnion(head, eye0, .1);
    d = sdfBlendUnion(d, eye1, .1);
    d = sdfBlendUnion(d, stick0, .15);
    d = sdfBlendUnion(d, stick1, .15);
    d = sdfBlendUnion(d, body0, .1);
    d = sdfBlendUnion(d, body1, .15);
    d = sdfBlendUnion(d, leg0l, .15);
    d = sdfBlendUnion(d, leg0r, .15);
    d = sdfBlendUnion(d, leg1l, .15);
    d = sdfBlendUnion(d, leg1r, .15);
    d = sdfBlendUnion(d, foot0l, .3);
    d = sdfBlendUnion(d, foot0r, .3);
    d = sdfBlendUnion(d, foot1l, .3);
    d = sdfBlendUnion(d, foot1r, .3);
    d = min(d, floord);
    return d;
}

vec3 calc_normal(vec3 p) {
	float d = scene_dist(p);
    vec2 e = vec2(.01, 0);
    vec3 n = d - vec3(
        scene_dist(p-e.xyy),
        scene_dist(p-e.yxy),
        scene_dist(p-e.yyx));
    return normalize(n);
}

vec3 calc_light(vec3 p){
	vec3 n = calc_normal(p);
    vec3 lpos = vec3(1, 5, 2);
    vec3 tol = lpos - p;
    float dist = length(tol);
    vec3 ldir = tol / dist;
    float str = max(AMBIENT,dot(n, ldir));
    float e = str * 5. / dist;
    if(e <= AMBIENT) return vec3(AMBIENT);
    float shadow = raymarch_s(p + n * EPSILON * 2., ldir, 8.);
    e *= shadow;
    e = max(AMBIENT, e);
    return vec3(e);
}

float raymarch_d(vec3 ro, vec3 rd){
	float dO = 0.;
    vec3 p;
    for(int i = 0; i < MAX_STEPS; i++){
    	p = ro + rd*dO;
        float dS = scene_dist(p);
        dO += dS;
        if(dO > MAX_DIST || dS < EPSILON)
            break;
    }
    return dO;
}

float raymarch_s(vec3 ro, vec3 rd, float k){
	float dO = 0.001;
    vec3 p;
    float res = 1.;
    for(int i = 0; i < MAX_STEPS; i++){
    	p = ro + rd*dO;
        float dS = scene_dist(p);
        dO += dS;
        res = min(res, k*dS/dO);
        if(dO > MAX_DIST) break;
    }
    return res;
}

vec3 raymarch_p(vec3 ro, vec3 rd){
	float dO = raymarch_d(ro, rd);
    return ro + rd * dO;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy) / iResolution.y;
	
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 1, 0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));
    vec3 p = raymarch_p(ro, rd);
    col = calc_light(p);
    
    fragColor = vec4(col,1.0);
}
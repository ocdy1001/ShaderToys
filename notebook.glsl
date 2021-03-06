//#### 2D SDF
// https://iquilezles.org/www/articles/smin/smin.htm
float op_union(float d1, float d2, float k){
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

float op_sub(float d1, float d2, float k){
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
}

float op_inter(float d1, float d2, float k){
    float h = max(k-abs(d1-d2),0.0);
    return max(d1, d2) + h*h*0.25/k;
}
// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm

//sdf for hor. line. xmm: min and max value for line x
float sdf_line_x(vec2 uv, vec2 xmm){
	return length(uv - vec2(clamp(uv.x, xmm.x, xmm.y), 0.));
}
//sdf for ver. line. ymm: min and max value for line y
float sdf_line_y(vec2 uv, vec2 ymm){
	return length(uv - vec2(0., clamp(uv.y, ymm.x, ymm.y)));
}

float sdf_circle(vec2 uv, vec2 pos, float rad){
	return length(uv - pos) - rad;
}

float sdf_rect(vec2 uv, vec2 pos, vec2 hsize){
    vec2 cwe = abs(uv - pos) - hsize;
    float outd = length(max(cwe, 0.0));
    float ind = min(max(cwe.x, cwe.y), 0.0);
    return outd + ind;
}

float sdf_triangle(vec2 uv, vec2 p0, vec2 p1, vec2 p2){
	vec2 e0 = p1 - p0;
	vec2 e1 = p2 - p1;
	vec2 e2 = p0 - p2;

	vec2 v0 = uv - p0;
	vec2 v1 = uv - p1;
	vec2 v2 = uv - p2;

	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );

    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));

	return -sqrt(d.x)*sign(d.y);
}

float pr_circle(vec2 uv, vec2 pos, float rad, float smoothness){
	return smoothstep(smoothness,0.0,sdf_circle(uv, pos, rad));
}

float pr_rect(vec2 uv, vec2 pos, vec2 hsize, float smoothness){
	return smoothstep(smoothness,0.0,sdf_rect(uv, pos, hsize));
}
//#### NOISE
//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float wn11(float n){return fract(sin(n) * 43758.5453123);}
//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float sn11(float p){
	float fl = floor(p);
  	float fc = fract(p);
	return mix(wn11(fl), wn11(fl + 1.0), fc);
}
//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float wn21(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	//uv *= pow(1.5,iTime) * .00000001;
    uv *= 1000000.;
    vec3 col = vec3(0.);

    col = vec3(wn21(uv));

    fragColor = vec4(col,1.0);
}

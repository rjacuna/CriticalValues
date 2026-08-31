from fractions import Fraction as F
from math import gcd
from functools import reduce

def trim(a):
    a=list(a)
    while a and a[-1]==0: a.pop()
    return a
def add(a,b):
    n=max(len(a),len(b)); return trim([ (a[i] if i<len(a) else 0)+(b[i] if i<len(b) else 0) for i in range(n)])
def sub(a,b):
    n=max(len(a),len(b)); return trim([ (a[i] if i<len(a) else 0)-(b[i] if i<len(b) else 0) for i in range(n)])
def mul(a,b):
    if not a or not b: return []
    r=[0]*(len(a)+len(b)-1)
    for i,x in enumerate(a):
        for j,y in enumerate(b): r[i+j]+=x*y
    return trim(r)
def deriv(a): return trim([i*a[i] for i in range(1,len(a))])
def comp(f,g):
    r=[]; 
    for c in reversed(f): r=add([c], mul(g,r))
    return r
def scaleX(m,p): return trim([c*m**j for j,c in enumerate(p)])
def content(p): return reduce(gcd,[abs(c) for c in p],0)
def divC(c,p):
    if c==0: return None
    if any(x % c for x in p): return None
    return trim([x//c for x in p])
def exact_div(p,q):
    if not q: return None
    if not p: return []
    p=list(p); out=[0]*(max(len(p)-len(q)+1,1))
    while p:
        if len(p)<len(q): return None
        if p[-1] % q[-1]: return None
        c=p[-1]//q[-1]; d=len(p)-len(q); out[d]=c
        t=[0]*d+[c]; p=sub(p,mul(q,t))
    return trim(out)

# --- Q[X] ---
def qtrim(a):
    a=list(a)
    while a and a[-1]==0: a.pop()
    return a
def qsub(a,b):
    n=max(len(a),len(b)); return qtrim([ (a[i] if i<len(a) else 0)-(b[i] if i<len(b) else 0) for i in range(n)])
def qmul(a,b):
    if not a or not b: return []
    r=[F(0)]*(len(a)+len(b)-1)
    for i,x in enumerate(a):
        for j,y in enumerate(b): r[i+j]+=x*y
    return qtrim(r)
def qdivmod(p,d):
    p=qtrim(p); d=qtrim(d); q=[]
    while p and len(p)>=len(d):
        k=len(p)-len(d); c=p[-1]/d[-1]; t=[F(0)]*k+[c]
        q=qtrim([ (q[i] if i<len(q) else 0)+(t[i] if i<len(t) else 0) for i in range(max(len(q),len(t)))])
        p=qsub(p,qmul(d,t))
    return q,p
def qextgcd(p,q):
    if not qtrim(q): return qtrim(p),[F(1)],[]
    d,r=qdivmod(p,q); g,a,b=qextgcd(q,r)
    return g,b,qsub(a,qmul(d,b))

def bezout(h):
    hq=[F(c) for c in h]; hq2=[F(c) for c in deriv(h)]
    g,a,b=qextgcd(hq,hq2)
    if len(g)!=1: return None
    c=g[0]; a=[x/c for x in a]; b=[x/c for x in b]
    d=reduce(lambda acc,r: acc*r.denominator//gcd(acc,r.denominator), a+b, 1)
    u=[int(x*d) for x in a]; v=[int(x*d) for x in b]
    e=gcd(gcd(content(u),content(v)),d)
    return divC(e,u),divC(e,v),d//e

def setup(f,h,f1,u,v,rho):
    h0=h[0]; m=rho*h0
    H=divC(h0,scaleX(m,h)); assert H is not None, "§2.1 H"
    W=divC(rho, sub(mul([v[0] if v else 0],H), scaleX(m,v))); assert W is not None, "§2.1 W"
    g=add(mul([m],[0,1]), mul(scaleX(m,h),W))
    return dict(h=h,f1=f1,u=u,v=v,rho=rho,M=m,h0=h0,H=H,W=W,g=g,f=f)

def check(s):
    f,h,H,W,g,rho,m,v=s['f'],s['h'],s['H'],s['W'],s['g'],s['rho'],s['M'],s['v']
    return dict(
      hbez = add(mul(s['u'],h),mul(v,deriv(h)))==[rho],
      hfac = f==mul(h,s['f1']),
      hH   = mul([s['h0']],H)==scaleX(m,h),
      hH0  = H[0]==1,
      hW   = mul([rho],W)==sub(mul([v[0] if v else 0],H),scaleX(m,v)),
      CpA  = exact_div(deriv(g),H) is not None,
      CpB  = exact_div(comp(f,g),mul(H,H)) is not None,
      degg = len(g)-1==len(h)-1+len(W)-1 and len(g)-1>=2,
    )

def s(p):
    if not p: return "0"
    out=[]
    for j,c in reversed(list(enumerate(p))):
        if c: out.append(f"{c}X^{j}" if j>1 else (f"{c}X" if j==1 else f"{c}"))
    return " + ".join(out)

print("--- spec's own Bezout data reproduces spec's g ---")
for name,f,h,f1,u,v,rho,expH,expW,expg in [
  ("8.1 p=3,q=2",[-3,2],[-3,2],[1],[],[1],2,[1,4],[0,2],[0,-12,-24]),
  ("8.2",[1,0,1],[1,0,1],[1],[2],[0,-1],2,[1,0,4],[0,1],[0,3,0,4]),
  ("8.3",[-2,0,0,1],[-2,0,0,1],[1],[3],[0,-1],-6,[1,0,0,-864],[0,-2],[0,16,0,0,-3456]),
]:
    st=setup(f,h,f1,u,v,rho)
    print(f"{name}: H={st['H']==expH} W={st['W']==expW} g={st['g']==expg}  checks={all(check(st).values())}")

print("--- program's own Bezout ---")
for name,f in [("X^2+1",[1,0,1]),("X^3-2",[-2,0,0,1]),("X^3-X-1",[-1,-1,0,1]),
               ("2X-3",[-3,2]),("X^4+1",[1,0,0,0,1]),
               ("8.5 X^3-X^2-2X-8",[-8,-2,-1,1])]:
    u,v,rho=bezout(f)
    st=setup(f,f,[1],u,v,rho)
    c=check(st)
    print(f"{name}: rho={rho} M={st['M']} H={s(st['H'])}")
    print(f"    g={s(st['g'])}")
    print(f"    checks: {all(c.values())} {[k for k,x in c.items() if not x]}")

# ---- factoring path ----
def qgcd(p,q):
    p=[F(c) for c in p]; q=[F(c) for c in q]
    while qtrim(q):
        p,q=q,qdivmod(p,q)[1]
    p=qtrim(p)
    return [x/p[-1] for x in p] if p else []
def clear(q):
    d=reduce(lambda acc,r: acc*r.denominator//gcd(acc,r.denominator), q, 1)
    return trim([int(x*d) for x in q])
def primpart(p):
    c=content(p)
    return divC(c,p) if c else p
def sqfree(f):
    g=qgcd(f,deriv(f))
    q,_=qdivmod([F(c) for c in f], g)
    return primpart(clear(q))
def stripX(p):
    while p and p[0]==0: p=exact_div(p,[0,1])
    return p
def divisors_pm(n):
    n=abs(n); return [d*s for d in range(1,n+1) if n%d==0 for s in (1,-1)]
def interp(pts):
    n=len(pts); res=[]
    for i,(xi,yi) in enumerate(pts):
        num=[F(1)]; den=F(1)
        for j,(xj,_) in enumerate(pts):
            if i==j: continue
            num=qmul(num,[F(-xj),F(1)]); den*= (F(xi)-F(xj))
        t=[c*F(yi)/den for c in num]
        res=qtrim([ (res[k] if k<len(res) else 0)+(t[k] if k<len(t) else 0) for k in range(max(len(res),len(t)))])
    if any(x.denominator!=1 for x in res): return None
    return trim([int(x) for x in res])
def evalp(p,x): 
    r=0
    for c in reversed(p): r=r*x+c
    return r
def proper_factor(p):
    d=(len(p)-1)//2
    pts=[]; x=0; k=0
    cand_x=[0]+[y for n in range(1,50) for y in (n,-n)]
    for x in cand_x:
        if len(pts)>d+0: break
        if evalp(p,x)!=0: pts.append(x)
        if len(pts)==d+1: break
    import itertools
    for ys in itertools.product(*[divisors_pm(evalp(p,x)) for x in pts]):
        c=interp(list(zip(pts,ys)))
        if c is None or len(c)-1<1 or len(c)-1>=len(p)-1: continue
        if exact_div(p,c) is not None: return c
    return None
def irr_factor(p):
    while len(p)-1>1:
        q=proper_factor(p)
        if q is None: return p
        p=q
    return p
def choose(f):
    s=stripX(sqfree(f))
    if not s or len(s)-1<1: return None
    return irr_factor(s)

print("--- factoring path ---")
tests=[("(X^2+1)(X-3)",mul([1,0,1],[-3,1])),("(X^2+1)^2",mul([1,0,1],[1,0,1])),
       ("X^4-1",[-1,0,0,0,1]),("(2X-3)(X^2+X+1)",mul([-3,2],[1,1,1])),
       ("(X^3-2)(X^2+1)",mul([-2,0,0,1],[1,0,1])),("X^2(X^2+1)",mul([0,0,1],[1,0,1]))]
for name,f in tests:
    if f[0]==0:
        print(f"{name}: X | f -> degenerate case g=X^2, H=X"); continue
    h=choose(f)
    f1=exact_div(f,h)
    if f1 is None: print(f"{name}: FAIL h does not divide f, h={s(h)}"); continue
    u,v,rho=bezout(h)
    st=setup(f,h,f1,u,v,rho); c=check(st)
    print(f"{name}: h={s(h)} rho={rho} M={st['M']} degH={len(st['H'])-1} degg={len(st['g'])-1} checks={all(c.values())} {[k for k,x in c.items() if not x]}")

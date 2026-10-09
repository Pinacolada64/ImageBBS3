10 rl = 1: rh = 10: sr = 5: rr = rh-rl
19 :
20 dim s(rr): dim r(sr-1)
21 for i=0 to rr: s(i) = i+rl: next
29 :
30 for i = 0 to sr-1
31 : v = int(rnd(0) * (rh-i)) : print s(v);
32 : r(i) = s(v)
33 : s(v) = s(rh-i-1)
35 next

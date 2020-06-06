scale :: Float -> Float -> Float -> Float
scale lo hi t = let m = (hi - lo)/(5 ** 0.5 - 1)
                    b = lo - m
                    in  m * t**0.5 + b

limit :: Float -> Float -> Float -> Float -> Float
limit lim lo hi t = let p  = lim * 4
                        m  = 5*hi - lo
                        ah = (lim * (5*lo-hi) + hi*lo*(-4))/(hi-lo)
                        in   (lim*t + ah) / (t + (p-m)/(hi-lo))

lim12345 lim lo hi = map (limit lim lo hi) (map (*1.3) [1..5])
# flutter_demo_monobank

https:&#x2F;&#x2F;dribbble.com&#x2F;shots&#x2F;5519790-Monobank-PFM

## 



This project attempts to recreate the design in the above dribble link

theirs:
https://cdn.dribbble.com/users/120141/videos/480/pfm.mp4

mine:
![Result](https://github.com/fdoyle/flutter_demo_monobank/blob/master/bank_demo.gif)

notable successes:
 - arc overlay looks pretty good, decent bit of math involved in that
 - inner icon is clipped to inner circle radius
 
notable differences:
 - color blending needs work. right now it's just an alpha blend, which doesn't look super great. 
the original design has kind of a spring effect on the trailing edge of the arc, my version is stiff. 
 - original has a bevel effect on the edges of the arc, making it appear lit from the top, but not especially consistently? I tried adding a lighter border along the dark edge of the arc, but it looked worse than without. 

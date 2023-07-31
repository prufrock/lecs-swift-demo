# lecs-swift-demo
A simple demo of using lecs-swift in an app

## 7500 entities at 60 fps
Apply random velocity changes to 7500 entities.

![7500 red squares bouncing around on an iphone screen](https://res.cloudinary.com/demmholkv/image/upload/v1690761464/7500e-60fps_nviijp.gif)

## 10,000 entities at 50 fps(need to optimize render pipeline)
Apply random velocity changes to 10000 entities.

![10,000 red squares bouncing around on an iphone screen](https://res.cloudinary.com/demmholkv/image/upload/v1690762394/10000e-50fps_ybjexh.gif)

## 200 entities at 60fps
With this number of entities it's easiest to see the difference in timing between using only arrays and using lecs-swift. Arrays are about 40 microseconds faster than lecs-swift. That's not a bad price to pay for being able to select the arrays to process :smile:.

Instruments report for the time it took run the code surrounding the system used to process the arrays.
![instruments read out count: 11,438 duration: 2.07s min duration: 33.29 µs avg duration: 180.60 µs std dev duration: 74.54 µs max duration 1.74 ms  ](https://res.cloudinary.com/demmholkv/image/upload/v1690761096/200a-instruments_hnjfjk.png)


Instruments report for the time it took to run the code surrounding the system used to process the entities.
![instruments read out count: 11,538 duration: 2.51s min duration: 50.33 µs avg duration: 217.78 µs std dev duration: 97.62 µs max duration 1.13 ms  ](https://res.cloudinary.com/demmholkv/image/upload/v1690761096/200e-instruments_wpra0s.png)

![200 red squares bouncing around on an iphone screen](https://res.cloudinary.com/demmholkv/image/upload/v1690761097/200e-60fps_mlzlll.gif)




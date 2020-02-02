
# [Main Plot](https://i.imgur.com/14eO4ef.gifv)

### Visualizing Chicago's Monthly Train Ridership Over Time

---

Each frame represents a month and the diameter of the points are proportional to the monthly ridership at each train stop. 

For comparison:

[October 2001](https://i.imgur.com/IgVlKuh.png) and [October 2018](https://i.imgur.com/eiHWKqz.png)

---
**Some takeaways:**

* Overall ridership peaked in 2015 and has been declining since then, likely due to the rise of uber/lyft

* Clark/Lake and State/Lake have massive amounts of riders, especially these last few years

* The southern part of the red line has actually lost riders while most other lines have gained riders

* There was a brief closure of the southern part of the red line in 2013 due to construction

---

# [Non-Seasonal Plot](https://i.imgur.com/zTozqZZ.gifv)

There is a seasonal component in the data as ridership declines in the winter when riders opt instead for cars or rideshares. To remove the visual effect of this seasonality I divided the total ridership by the monthly, so now each month has the same average ridership.

We can see that certain stops still have some seasonality, likely due to their seasonality components being shaped different from the general seasonality of all the train stops. Some examples are O'Hare being more affected by the seasonality of air travel and the Brown Line stops being more affected by the seasonality of the Depaul school year.

---

**Sources:**

Ridership data and train stop coordinates obtained from https://data.cityofchicago.org/

Visualizations and analysis were in R using:  
ggmap  
stringr  
dplyr

Animation made using ImageMagick


# ------------------------------------------------------------------------- #
# --------- Adding types, but not tokens, affects property induction ------ #
# ----------------- Modeling Experiment 1 conditions ---------------------- #
# -------------------------------------------------------------------------- #

library(cowplot)
library(tidyverse)
library(ggpubr)
library(BayesFactor)

# rm(list = ls()) # use Ctrl + Shift + F10 to clear environment
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source("./BayesGen-BX.R")
set.seed(1)

# ------------ PARAMETERS ----------------------------- #
phi <- 1                 # phi = 1: uniform prior over hypotheses, phi > 1: greater prior belief in larger hypotheses
nits <- 1000             # number of iterations

# initial values for test items - overriden later on, depends on randomly-sampled type values
test <- c(.51, .707, .9) # similarity values for high-, med-, low-sim test/generalization items
nt <- length(test)       # number of test items

# --------------------------- generate predictions ------------------------------ #
parits <- 3000  # how many times do I want to test out different parameter values?

typesCols <- c("1token", "2tokens", "3tokens")
typesHigh <- matrix(data = c(rep(0, parits*3)), nrow = parits)
colnames(typesHigh) <- typesCols  # does adding types increase gen at high categories?

typesMed <- typesHigh             # does adding types decrease gen at med categories?
typesLow <- typesHigh             

tokensCols <- c("1type", "2types", "3types")
tokensHigh <- typesHigh
colnames(tokensHigh) <- tokensCols

tokensLow <- tokensMed <- tokensHigh

pars <- c("thetaType", "thetaToken", "target1", "target2", "target3", "target4", "typesd", "tokensd")
parValues <- matrix(data = c(rep(0, parits*length(pars))), nrow = parits)
colnames(parValues) <- pars

# use a loop to test different parameter values
for (a in 1:parits) {
  
  # sample different parameter values
  # theta values to represent sampling assumptions/informational value
  thetaType <- runif(1, min = .1, max = .5)          # value used to discuss modeling results = .3
  # thetaType <- .1          # value used to discuss modeling results = .3
  thetaToken <- runif(1, min = .1, max = thetaType)  # value in paper = .15
  
  # stimulus values for types
  targetsM <- runif(1, .2, .6) # select the centre of a uniform distribution, from which to sample types
  targetsW <- runif(1, .005, .2)  # select the width of a uniform distribution, from which to sample types
  
  targets <- runif(4, targetsM - targetsW, targetsM + targetsW) # sample from that uniform distribution
  targets <- sort(targets)
  target1 <- targets[2]  # value in paper = .45
  target2 <- targets[3]                   # .46
  target3 <- targets[1]                   # .44
  target4 <- targets[4]                   # .47
  
  # when randomly generating stimulus values for types/tokens, how much standard deviation to use?
  # typesd <- runif(1, .01, .1)             # .06
  typesd <- .01             # .06
  tokensd <- typesd/6                     # .009

  bg1 <- matrix(data = c(rep(0, nits*nt)),   # create enough 0s for each iteration to fill with predicted generalisation probability
                nrow = nt)                   # 1 row for each test item (high, medium, low sim)
  bg11 <- bg111 <- bg1111 <- bg2 <- bg3 <- bg4 <- bg1    # need one matrix per condition
  bg2v1 <- bg2v2 <- bg3v2 <- bg4v2 <- bg1
  bg31 <- bg21 <- bg211 <- bg2
  
    for( i in 1:nits ) {     # average out predictions over nits iterations
    
      train1 <- rnorm(1, mean = target1, sd = typesd) # generates value for 1st type from a normal distribution
      train2 <- rnorm(1, mean = target2, sd = typesd)
      train3 <- rnorm(1, mean = target3, sd = typesd)
      train4 <- rnorm(1, mean = target4, sd = typesd)
      
      # generalisation from adding types
      testH <- (max(c(train1, train2, train3, train4)) + .05)
      test <- c(testH, testH + ((.9 - testH) / 2), .9)
      
      # for each iteration, fill the next column with gen probabilities for high, medium, low sim categories (in that order)
      bg1[,i] <- BayesGen(train1, test, thetaType, phi)                # generalisation based on 1 type
      bg11[,i] <- BayesGen(c(train1, train2), test, thetaType, phi)    # generalisation based on 2 types
      bg111[,i] <- BayesGen(c(train1, train2, train3), test, thetaType, phi)          # based on 3 types
      bg1111[,i] <- BayesGen(c(train1, train2, train3, train4), test, thetaType, phi)          # 4 types
      
      # generalisation from adding tokens 
      train1a <- rnorm(1, mean = train1, sd = tokensd)  # the token is constrained to be within a range around the first type
      train1b <- rnorm(1, mean = train1, sd = tokensd)  # the above is true for all tokens
      train1c <- rnorm(1, mean = train1, sd = tokensd)
      
      bg2[,i] <- (BayesGen(train1, test, thetaType, phi))*1/2 +
                    (BayesGen(train1a, test, thetaToken, phi))*1/2
      
      bg3[,i] <- (BayesGen(train1, test, thetaType, phi))*1/3 +
                    (BayesGen(c(train1a, train1b), test, thetaToken, phi))*2/3
      
      bg4[,i] <- (BayesGen(train1, test, thetaType, phi))*1/4 +
        (BayesGen(c(train1a, train1b, train1c), test, thetaToken, phi))*3/4
      
      # adding types with 2 tokens
      bg21[,i] <- (BayesGen(c(train1, train2), test, thetaType, phi))*2/3 +
                     (BayesGen(train1a, test, thetaToken, phi))*1/3
      bg211[,i] <- (BayesGen(c(train1, train2, train3), test, thetaType, phi))*3/4 +
                     (BayesGen(train1a, test, thetaToken, phi))*1/4
      
      # adding types with 3 tokens
      bg31[,i] <- (BayesGen(c(train1, train2), test, thetaType, phi))*2/4 +
                    (BayesGen(c(train1a, train1b), test, thetaToken, phi))*2/4
    }
    
    # ------------------ effect of adding types  ---------------------------- #
    bg1 <- rowMeans(bg1)          # calculate the mean of the N(nits) generalisation probabilities for each similarity category
    bg11 <- rowMeans(bg11)        # for 11 condition
    bg111 <- rowMeans(bg111)      # for 111 condition etc.,
    bg1111 <- rowMeans(bg1111)

    bg2 <- rowMeans(bg2)
    bg21 <- rowMeans(bg21)
    bg211 <- rowMeans(bg211)

    bg3 <- rowMeans(bg3)
    bg31 <- rowMeans(bg31)

    typesHigh[a,1] <- bg1[1] < bg1111[1]  # adding types (from 1 -> 1111) increases gen at high-sim category?
    typesHigh[a,2] <- bg2[1] < bg211[1]   # adding types (From 2 -> 211) increases gen at high-sim category?
    typesHigh[a,3] <- bg3[1] < bg31[1]    # adding types (from 3 -> 31) increase gen at high-sim category?

    typesMed[a,1] <- bg1[2] > bg1111[2]  # adding types decreases gen at medium-sim category?
    typesMed[a,2] <- bg2[2] > bg211[2]
    typesMed[a,3] <- bg3[2] > bg31[2]

    typesLow[a,1] <- bg1[3] > bg1111[3]  # adding types decreases gen at low-sim categories?
    typesLow[a,2] <- bg2[3] > bg211[3]  # adding types decreases gen at low-sim categories?
    typesLow[a,3] <- bg3[3] > bg31[3]  # adding types decreases gen at low-sim categories?
    
    gap <- .05
    tokensHigh[a,1] <- between(bg4[1], left = 0, right = bg1[1] + gap)
    tokensHigh[a,2] <- between(bg31[1], left = 0, right = bg11[1] + gap)
    tokensHigh[a,3] <- between(bg211[1], left = 0, right = bg111[1] + gap)
    
    # tokensHigh[a,1] <- bg1[1] >= bg4[1]  # adding tokens decreases or does not change generalisation
    # tokensHigh[a,2] <- bg11[1] >= bg31[1]
    # tokensHigh[a,3] <- bg111[1] >= bg211[1]

    tokensMed[a,1] <- between(bg4[2], left = 0, right = bg1[2] + gap)
    tokensMed[a,2] <- between(bg31[2], left = 0, right = bg11[2] + gap)
    tokensMed[a,3] <- between(bg211[2], left = 0, right = bg111[2] + gap)
    
    # tokensMed[a,1] <- bg1[2] >= bg4[2]  # adding tokens decreases or does not change generalisation
    # tokensMed[a,2] <- bg11[2] >= bg31[2]
    # tokensMed[a,3] <- bg111[2] >= bg211[2]
    
    tokensLow[a,1] <- between(bg4[3], left = 0, right = bg1[3] + gap)
    tokensLow[a,2] <- between(bg31[3], left = 0, right = bg11[3] + gap)
    tokensLow[a,3] <- between(bg211[3], left = 0, right = bg111[3] + gap)
    
    # tokensLow[a,1] <- bg1[3] >= bg4[3]  # adding tokens decreases or does not change generalisation
    # tokensLow[a,2] <- bg11[3] >= bg31[3]
    # tokensLow[a,3] <- bg111[3] >= bg211[3]

    parValues[a,] <- c(thetaType, thetaToken, target1, target2, target3, target4, typesd, tokensd)
}

# cbind(typesHigh, parValues)
# typesHigh
# typesMed
# typesLow
# 
# tokensHigh
# tokensMed
# tokensLow

# ------ how many times did adding types -> tightening? ------ #
sum(typesHigh[,1])  # how many times the pattern occurred (1 high-sim gen rating < 1111 high-sim gen rating)
sum(typesHigh[,2])  # how many times the pattern occurred (2 high-sim gen rating < 211 high-sim gen rating)
sum(typesHigh[,3])  # how many times the pattern occurred (3 high-sim gen rating < 31 high-sim gen rating)

sum(typesMed[,1])  # 1 med-sim gen rating > 1111 med-sim gen rating
sum(typesMed[,2])  # 2 med-sim gen rating > 211 med-sim gen rating
sum(typesMed[,3])  # 3 med-sim gen rating > 31 med-sim gen rating

sum(typesLow[,1])  # 1 low-sim gen rating > 1111 low-sim gen rating
sum(typesLow[,2])  # 2 low-sim gen rating > 211 low-sim gen rating
sum(typesLow[,3])  # 3 low-sim gen rating > 31 low-sim gen rating

typesMed3 <- cbind(typesMed[,3], parValues)
head(typesMed3)
colnames(typesMed3)[1] <- "decreased"
# write.csv(typesMed3, "./typesMed3.csv")

typesMed3 <- read.csv("./typesMed3.csv")

typesMed3 <- as.data.frame(typesMed3)
typesMed3 <- pivot_longer(typesMed3, thetaType:tokensd, names_to = "parameter", values_to = "value")
typesMed3$decreased <- as.character(as.numeric(typesMed3$decreased))
typesMed3$decreased <- gsub("0", "Did not reproduce", typesMed3$decreased)
typesMed3$decreased <- gsub("1", "Reproduced", typesMed3$decreased)

library(plyr)
mu <- ddply(typesMed3, c("decreased", "parameter"), summarise, grp.mean=mean(value))

ggplot(typesMed3, aes(x=value)) +
  geom_histogram(bins = 20) +
  geom_vline(data=mu, aes(xintercept=grp.mean, color="red"), linetype="dashed") +
  labs(
    # title = "Experiment 3: Adding type-label instances decreases gen for high-similarity items", 
    x = "Parameter value", y = "Count") +
  # geom_vline(data=mu, aes(xintercept=grp.mode, color="blue"), linetype="dotted") +
  facet_wrap(~ decreased + parameter, scales = "free") +
  theme_bw() +
  theme(legend.position = "none")

library(e1071)
summ <- ddply(typesMed3, c("decreased", "parameter"), summarise,
      mean = mean(value), sd = sd(value), median = median(value), skew = skewness(value))
# write.csv(summ, "./typesMed3_parameters.csv")

# ------- how many times did adding tokens -> decreased gen/no diff? --- #
sum(tokensHigh[,1])  # how many times the pattern occurred (4(H) is between 0 - (1(H) + .05))
sum(tokensHigh[,2])  # how many times the pattern occurred (31(H) is between 0 - (11(H) + .05))
sum(tokensHigh[,3])  # how many times the pattern occurred (211(H) is between 0 - (111(H) + .05))

sum(tokensMed[,1])  # 4(M) is between 0 - (1(M) + .05)
sum(tokensMed[,2])  # 31(M) is between 0 - (11(M) + .05)
sum(tokensMed[,3])  # 211(M) is between 0 - (111(M) + .05)

sum(tokensLow[,1])  # 4(L) is between 0 - (1(L) + .05)
sum(tokensLow[,2])  # 31(L) is between 0 - (11(L) + .05)
sum(tokensLow[,3])  # 211(L) is between 0 - (111(L) + .05)


# trains <- c(train1, train2, train3, train4)        # collate the training stimulus values
# trains <- as.data.frame(trains)
# 
# ggTypes <- ggplot(vals, aes(x = test, y = genProb)) +     # plot predicted generalisation ratings
#   geom_point(aes(x = test, y = genProb, group = genCond, colour = genCond), size = 2) +
#   geom_line(aes(colour = genCond, linetype = genCond), size = 1.4) +
#   theme_bw(base_size = 12) +
#   labs(title = "Adding types with 1 token", x = "Stimulus value", y = "Generalisation Probability") +
#   scale_x_continuous(limits = c(min(trains), 1), breaks = seq(.4, 1, by = .1)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = .2)) +
#   scale_color_manual(name = "Evidence Sample", labels = c("1", "11", "111", "1111"), values = c("red", "coral1", "seagreen", "slateblue3")) +
#   scale_linetype_manual(name = "Evidence Sample", labels = c("1", "11", "111", "1111"), values = c("solid", "longdash", "dotdash", "dotted")) +
#   geom_point(data = trains, aes(x = trains, y = 1)) +    # show training stimulus values
#   geom_vline(xintercept = test, linetype = "dashed", colour = "blue")  +
#   theme(legend.position = c(.8, .7))
# 
# # # ----------------- effect of adding tokens ------------------------ #
# 
# valsTokes <- as.data.frame(cbind(test, bg1, bg2, bg3, bg4))
# valsTokes <- gather(valsTokes, key = "genCond", value = "genProb", -test)

# trainsTokes <- c(train1, train1a, train1b, train1c)
# trainsTokes <- as.data.frame(trainsTokes)
# 
# ggTokens <- ggplot(valsTokes, aes(x = test, y = genProb)) +
#   geom_point(aes(x = test, y = genProb, group = genCond, colour = genCond), size = 2) +
#   geom_line(aes(colour = genCond, linetype = genCond), size = 1.4) +
#   theme_bw(base_size = 12) +
#   labs(title = "Adding tokens with 1 type", x = "Stimulus value", y = "Generalisation Probability") +
#   scale_x_continuous(limits = c(min(trains), 1), breaks = seq(.4, 1, by = .1)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = .2)) +
#   scale_color_manual(name = "Evidence Sample", labels = c("1", "2", "3", "4"), values = c("red", "coral1", "seagreen", "slateblue3")) +
#   scale_linetype_manual(name = "Evidence Sample", labels = c("1", "2", "3", "4"), values = c("solid", "longdash", "dotdash", "dotted")) +
#   geom_point(data = trainsTokes, aes(x = trainsTokes, y = 1)) +
#   geom_vline(xintercept = test, linetype = "dashed", colour = "blue") +
#   theme(legend.position = c(.8, .7))
# 
# # adding types with 2 tokens
# 
# valsTy1 <- as.data.frame(cbind(test, bg2, bg21, bg211))
# valsTy1 <- gather(valsTy1, key = "genCond", value = "genProb", bg2:bg211)
# trainsTy1 <- c(train1, train2, train3, train1a, train1b)
# trainsTy1 <- as.data.frame(trainsTy1)
# 
# ggTypes1 <- ggplot(valsTy1, aes(x = test, y = genProb)) +     # plot predicted generalisation ratings
#   geom_point(aes(x = test, y = genProb, group = genCond, colour = genCond), size = 2) +
#   geom_line(aes(colour = genCond, linetype = genCond), size = 1.4) +
#   theme_bw(base_size = 12) +
#   labs(title = "With 2 tokens", x = "Stimulus value", y = "Generalisation Probability") +
#   scale_x_continuous(limits = c(min(trains), 1), breaks = seq(.4, 1, by = .1)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = .2)) +
#   scale_color_manual(name = "Evidence Sample", labels = c("2", "21", "211"), values = c("red", "coral1", "seagreen")) +
#   scale_linetype_manual(name = "Evidence Sample", labels = c("2", "21", "211"), values = c("solid", "longdash", "dotdash")) +
#   geom_point(data = trainsTy1, aes(x = trainsTy1, y = 1)) +    # show training stimulus values
#   geom_vline(xintercept = test, linetype = "dashed", colour = "blue")  +
#   theme(legend.position = c(.8, .7))
# # ggTypes1
# 
# # adding types with 3 tokens
# bg31 <- rowMeans(bg31)
# valsTy2 <- as.data.frame(cbind(test, bg3, bg31))
# valsTy2 <- gather(valsTy2, key = "genCond", value = "genProb", bg3:bg31)
# trainsTy2 <- c(train1, train2, train1a, train1b)
# trainsTy2 <- as.data.frame(trainsTy2)
# 
# ggTypes2 <- ggplot(valsTy2, aes(x = test, y = genProb)) +     # plot predicted generalisation ratings
#   geom_point(aes(x = test, y = genProb, group = genCond, colour = genCond), size = 2) +
#   geom_line(aes(colour = genCond, linetype = genCond), size = 1.4) +
#   theme_bw(base_size = 12) +
#   labs(title = "With 3 tokens", x = "Stimulus value", y = "Generalisation Probability") +
#   scale_x_continuous(limits = c(min(trains), 1), breaks = seq(.4, 1, by = .1)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = .2)) +
#   scale_color_manual(name = "Evidence Sample", labels = c("3", "31"), values = c("red", "coral1")) +
#   scale_linetype_manual(name = "Evidence Sample", labels = c("3", "31"), values = c("solid", "longdash")) +
#   geom_point(data = trainsTy1, aes(x = trainsTy1, y = 1)) +    # show training stimulus values
#   geom_vline(xintercept = test, linetype = "dashed", colour = "blue")  +
#   theme(legend.position = c(.8, .7))
# # ggTypes2
# 
# # adding tokens with 2 types
# valsTok2 <- as.data.frame(cbind(test, bg11, bg21, bg31))
# valsTok2 <- gather(valsTok2, key = "genCond", value = "genProb", bg11:bg31)
# trainsTok2 <- c(train1, train2, train1a, train1b)
# trainsTok2 <- as.data.frame(trainsTok2)
# 
# ggTok2 <- ggplot(valsTok2, aes(x = test, y = genProb)) +     # plot predicted generalisation ratings
#   geom_point(aes(x = test, y = genProb, group = genCond, colour = genCond), size = 2) +
#   geom_line(aes(colour = genCond, linetype = genCond), size = 1.4) +
#   theme_bw(base_size = 12) +
#   labs(title = "With 2 types", x = "Stimulus value", y = "Generalisation Probability") +
#   scale_x_continuous(limits = c(min(trains), 1), breaks = seq(.4, 1, by = .1)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = .2)) +
#   scale_color_manual(name = "Evidence Sample", labels = c("11", "21", "31"), values = c("red", "coral1", "seagreen")) +
#   scale_linetype_manual(name = "Evidence Sample", labels = c("11", "21", "31"), values = c("solid", "longdash", "dotdash")) +
#   geom_point(data = trainsTok2, aes(x = trainsTok2, y = 1)) +    # show training stimulus values
#   geom_vline(xintercept = test, linetype = "dashed", colour = "blue")  +
#   theme(legend.position = c(.8, .7))
# # ggTok2
# 
# # adding tokens with 3 types
# valsTok3 <- as.data.frame(cbind(test, bg111, bg211))
# valsTok3 <- gather(valsTok3, key = "genCond", value = "genProb", bg111:bg211)
# trainsTok3 <- c(train1, train2, train3, train1a)
# trainsTok3 <- as.data.frame(trainsTok3)
# 
# ggTok3 <- ggplot(valsTok3, aes(x = test, y = genProb)) +     # plot predicted generalisation ratings
#   geom_point(aes(x = test, y = genProb, group = genCond, colour = genCond), size = 2) +
#   geom_line(aes(colour = genCond, linetype = genCond), size = 1.4) +
#   theme_bw(base_size = 12) +
#   labs(title = "With 3 types", x = "Stimulus value", y = "Generalisation Probability") +
#   scale_x_continuous(limits = c(min(trains), 1), breaks = seq(.4, 1, by = .1)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = .2)) +
#   scale_color_manual(name = "Evidence Sample", labels = c("111", "211"), values = c("red", "coral1")) +
#   scale_linetype_manual(name = "Evidence Sample", labels = c("111", "211"), values = c("solid", "longdash")) +
#   geom_point(data = trainsTok3, aes(x = trainsTok3, y = 1)) +    # show training stimulus values
#   geom_vline(xintercept = test, linetype = "dashed", colour = "blue")  +
#   theme(legend.position = c(.8, .7))
# # ggTok3



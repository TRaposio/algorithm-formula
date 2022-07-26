## Imports
library(GGally)
library(ellipse)
install.packages("reshape2")
library(reshape2)
library(rgl)

df = CFOPalgs_df
summary(df)
print(sapply(df,function(x) any(is.na(x))))

## First analysis - Relationship between predictors and response
ggpairs(data = df[ , c('Time', 'SHTM', 'Double', 'Risk')], title ="Relationships between predictors & response",
        lower = list(continuous=wrap("points", alpha = 0.5, size=0.1)))

## base model
g = lm( Time ~ SHTM + Double + Risk + Overwork + Slice + SoftRegr + HardRegr, data = df )
summary(g)
gs = summary(g)

## Confidence Region of two variables
#SHTM & DOUBLE
p = g$rank 
n = dim(df)[1] 

alpha = 0.05
t_alpha2 = qt( 1-alpha/2, n-p )
beta_hat_SHTM = g$coefficients[2]
se_beta_hat_SHTM = summary( g )[[4]][2,2]
IC_SHTM = c( beta_hat_SHTM - t_alpha2 * se_beta_hat_SHTM,
             beta_hat_SHTM + t_alpha2 * se_beta_hat_SHTM )
IC_SHTM

beta_hat_Double = g$coefficients[3]
se_beta_hat_Double = summary( g )[[4]][3,2]
IC_Double = c( beta_hat_Double- t_alpha2 * se_beta_hat_Double,
             beta_hat_Double + t_alpha2 * se_beta_hat_Double )
IC_Double

#plot
plot( ellipse( g, c( 2, 3 ) ), type = "l", xlim = c( 0., 0.1 ) )
points( 0, 0 )
points( g$coef[ 2 ] , g$coef[ 3 ] , pch = 18 )

abline( v = c( IC_SHTM[1], IC_SHTM[2] ), lty = 2 )
abline( h = c( IC_Double[1], IC_Double[2] ), lty = 2 )

#Overwork & Risk
p = g$rank 
n = dim(df)[1] 

alpha = 0.05
t_alpha2 = qt( 1-alpha/2, n-p )
beta_hat_OW = g$coefficients[5]
se_beta_hat_OW = summary( g )[[4]][5,2]
IC_OW = c( beta_hat_OW - t_alpha2 * se_beta_hat_OW,
             beta_hat_OW + t_alpha2 * se_beta_hat_OW )
IC_OW

beta_hat_Risk = g$coefficients[4]
se_beta_hat_Risk = summary( g )[[4]][4,2]
IC_Risk= c( beta_hat_Risk- t_alpha2 * se_beta_hat_Risk,
               beta_hat_Risk + t_alpha2 * se_beta_hat_Risk)
IC_Risk

#plot
plot( ellipse( g, c( 5, 4 ) ), type = "l", xlim = c( -0.05, 0.05 ) , ylim = c(0,2.4))
points( 0, 0 )
points( g$coef[ 5 ] , g$coef[ 4 ] , pch = 18 )

abline( v = c( IC_OW[1], IC_OW[2] ), lty = 2 )
abline( h = c( IC_Risk[1], IC_Risk[2] ), lty = 2 )

## Heatmap
corr_mat <- round(cor(df[ , c('Time', 'SHTM', 'Double', 'Risk', 'Overwork', 'Slice', 'SoftRegr', 'HardRegr')]),2)
melted_corr_mat <- melt(corr_mat)

ggplot(data = melted_corr_mat, aes(x = Var1, y = Var2, fill=value)) + geom_tile() + scale_fill_gradient(low="white", high="black") 


## Verify model assumptions
#Homoscedasticity
plot( g$fit, g$res, xlab = "Fitted", ylab = "Residuals",
      main = "Residuals vs Fitted Values", pch = 16 )
abline( h = 0, lwd = 2, lty = 2, col = 'red' )

#Normality
qqnorm( g$res, ylab = "Raw Residuals", pch = 16 )
qqline( g$res )

shapiro.test( g$res ) #normal distribution if p-value is hugh

hist( g$res, 10, probability = TRUE, col = 'lavender', main = 'residuals' ) #histogram

## Improving the model

## vif
vif( g ) #high values suggest that a variable can be explained by all others in the dataset
         #no higher values suggest that some variables may be masking or suppressing others

# I remove covariates starting from the less significant ones
#remove overwork
g2 = lm( Time ~ SHTM + Double + Risk + Slice + SoftRegr + HardRegr, data = df )
summary(g2)

#remove double
g3 = lm( Time ~ SHTM + Risk + Overwork + Slice + SoftRegr + HardRegr, data = df )
summary(g3)

## remove slice
gs = lm( Time ~ SHTM + Risk + Overwork + Slice + SoftRegr + HardRegr, data = df )
summary(gs)

#remove double and overwork
g4 = lm( Time ~ SHTM + Risk + Slice + SoftRegr + HardRegr, data = df )
summary(g4)

#remove all three
g5 = lm( Time ~ SHTM + Risk+ SoftRegr + HardRegr, data = df )
summary(g5)

## leverages

X = model.matrix( g5 )
lev = hat( X )

plot( g5$fitted.values, lev, ylab = "Leverages", main = "Plot of Leverages",
      pch = 16, col = 'black' )
abline( h = 2 * p/n, lty = 2, col = 'red' )
watchout_points_lev = lev[ which( lev > 2 * p/n  ) ]
watchout_ids_lev = seq_along( lev )[ which( lev > 2 * p/n ) ]
points( g5$fitted.values[ watchout_ids_lev ], watchout_points_lev, col = 'red', pch = 16 )

#model without leverage points
lev[lev> 2*p/n]
gl = lm( Time ~ SHTM + Risk + SoftRegr + HardRegr, data = df, subset = ( lev < 0.2 ))
summary(gl)

#relative change of coefficients
abs( ( g5$coefficients - gl$coefficients ) / g5$coefficients )

#more complex plot of leverages
colors = rep( 'black', nrow( df ) )
colors[ watchout_ids_lev ] = c('red', 'blue', 'green', 'orange')
pairs( df[ , c( 'SHTM', 'Risk', 'SoftRegr', 'HardRegr' ) ],
       pch = 16, col = colors, cex = 1 + 0.5 * as.numeric( colors != 'black' ))

## residuals
#plot of residuals
plot( g5$res, ylab = "Residuals", main = "Plot of residuals" )
sort( g5$res )

#standardized residuals
gs = summary(g5)
res_std = g5$res/gs$sigma
watchout_ids_rstd = which( abs( res_std ) > 2 )
watchout_rstd = res_std[ watchout_ids_rstd ] 
watchout_rstd

plot( g5$fitted.values, res_std, ylab = "Standardized Residuals", main = "Standardized Residuals")
abline( h = c(-2,2), lty = 2, col = 'orange' )
points( g5$fitted.values[watchout_ids_rstd],
        res_std[watchout_ids_rstd], col = 'red', pch = 16 )
points( g5$fitted.values[watchout_ids_lev],
        res_std[watchout_ids_lev], col = 'orange', pch = 16 )
legend('topright', col = c('red','orange'),
       c('Standardized Residuals', 'Leverages'), pch = rep( 16, 2 ), bty = 'n' )

#studentized residuals
stud = g5$residuals / ( gs$sigma * sqrt( 1 - lev ) )
stud = rstandard( g5 )
watchout_ids_stud = which( abs( stud ) > 2 )
watchout_stud = stud[ watchout_ids_stud ]
plot( g5$fitted.values, stud, ylab = "Studentized Residuals", main = "Studentized Residuals")
points( g5$fitted.values[watchout_ids_stud],
        stud[watchout_ids_stud], col = 'pink', pch = 16 )
points( g5$fitted.values[watchout_ids_lev],
        stud[watchout_ids_lev], col = 'orange', pch = 16 )
abline( h = c(-2,2), lty = 2, col = 'orange' )
legend('topright', col = c('pink','orange'),
       c('Studentized Residual', 'Leverages'), pch = rep( 16, 3 ), bty = 'n' )

## cook distance
Cdist = cooks.distance( g5 )
watchout_ids_Cdist = which( Cdist > 4/(n-p) ) 
watchout_Cdist = Cdist[ watchout_ids_Cdist ] 
watchout_Cdist
plot( g5$fitted.values, Cdist, pch = 16, xlab = 'Fitted values',
      ylab = 'Cooks Distance', main = 'Cooks Distance' )
points( g5$fitted.values[ watchout_ids_Cdist ], Cdist[ watchout_ids_Cdist ],
        col = 'green', pch = 16 )

#model without leverage points identified by cook's distance
id_to_keep = !( 1:n %in% watchout_ids_Cdist )
gl = lm( Time ~ SHTM + Risk + SoftRegr + HardRegr, data = df[ id_to_keep, ]  )
summary(gl)

#Model selection
## AIC e BIC
AIC( g )
BIC( g ) #first model

AIC(g5)
BIC(g5) #improved model

AIC(gl)
BIC(gl) #no leverages


## comparison with anova
anova(g5, g) # high p values suggest that adding variables doesn't enrich the model





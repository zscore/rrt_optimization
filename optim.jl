using DataFrames
using JuMP
Using Clp

rrt = readtable("dat/rrt.csv")

month_names = vec([string('m', year, '_', month) for year=2016:2017,month=1:12])
month_pref = rrt[month_names]
month_pref = rrt[vec([string('m', year, '_', month) for year=2016:2017,month=1:12])]

# for i = 1:12
# 	rename!(rrt, "m2016_$i", i)
# end

# for i = 1:12
# 	rename!(rrt, "m2017_$i", i + 12)
# end

# rename!(rrt.colindex, [(symbol("m2016_$i")=>symbol("$i")) for i in 1:12])
# rename!(rrt, "m2016_1", "1")

tot_employ,total_vars = size(rrt)
tot_month = 24

m = Model()
@defVar(m, month_assgn[1:tot_employ, 1:tot_month], Bin)
# @defExpr(m, expr[i=1:3], i*sum{x[j], j=1:3})
# @defExpr(m, tot_spanish[month=1:tot_month],
# 	sum{month_assgn[employ, month] * rrt[employ, "spanish"], employ=1:tot_employ})
# Employees serve according to preference
@addConstraint(m, no_pref_confl[employ=1:tot_employ,month=1:tot_month],
			   month_assgn[employ, month] + month_pref[employ, month] <= 1)
# Each group contains 40 people
@addConstraint(m, monthly_team_size[month=1:tot_month],
			   sum{month_assgn[employ, month], employ=1:tot_employ} >= 40)
# Two assignments per employee per year
@addConstraint(m, two_months_in_2016[employ=1:tot_employ],
			   sum(month_assgn[employ, 1:12]) == 2)
@addConstraint(m, two_months_in_2017[employ=1:tot_employ],
			   sum(month_assgn[employ, 13:24]) == 2)
# At least 4 spanish speakers every month
@addConstraint(m, suff_spanish[month=1:tot_month],
	AffExpr(month_assgn[:, month], float64(vector(rrt["spanish"])), 0.0) >= 4.0)
# At least 2 French Speakers every month
@addConstraint(m, suff_french[month=1:tot_month],
	sum{month_assgn[employ, month] * rrt[employ, "french"], employ=1:tot_employ} >= 2)
# At least 1 logistics employee every month
@addConstraint(m, suff_logistics[month=1:tot_month],
	sum{month_assgn[employ, month] * rrt[employ, "logistics"], employ=1:tot_employ} >= 1)
# At least 4 medical officers every month
@addConstraint(m, suff_medofficer[month=1:tot_month],
	sum{month_assgn[employ, month] * rrt[employ, "medofficer"], employ=1:tot_employ} >= 4)


# addConstraint(m, y + z == 4)  # Other options: <= and >=
@addConstraint(m, no_pref_confl[employ=1:tot_employ,month=1:tot_month],
			   month_assgn[employ, month] + month_pref[employ, month] <= 1)
setObjective(m, :Min, sum(month_assgn)) # or :Min

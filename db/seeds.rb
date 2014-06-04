site = Site.create url: 'wearepolymathic.com'
user = User.create email: 'test@email.com',
                   password: 'password'

user.sites << site

rule_set = site.rule_sets.create
rule = rule_set.rules.create
bar = rule_set.bars.create goal: "CollectEmail"

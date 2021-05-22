const Settings = require('settings-sharelatex')
const fs = require('fs')
const Path = require('path')

// The groups.json file encodes the various group plan options we provide, and
// is used in the app the render the appropriate dialog in the plans page, and
// to generate the appropriate entries in the Settings.plans array.
// It is also used by scripts/recurly/sync_recurly.rb, which will make sure
// Recurly has a plan configured for all the groups, and that the prices are
// up to date with the data in groups.json.
const data = fs.readFileSync(
  Path.join(__dirname, '/../../../templates/plans/groups.json')
)
const groups = JSON.parse(data.toString())

const capitalize = string => string.charAt(0).toUpperCase() + string.slice(1)

// With group accounts in Recurly, we end up with a lot of plans to manage.
// Rather than hand coding them in the settings file, and then needing to keep
// that data in sync with the data in groups.json, we can auto generate the
// group plan entries and append them to Settings.plans at boot time. This is not
// a particularly clean pattern, since it's a little surprising that settings
// are modified at boot-time, but I think it's a better option than trying to
// keep two sources of data in sync.
for (const [usage, planData] of Object.entries(groups)) {
  for (const [planCode, currencyData] of Object.entries(planData)) {
    // Gather all possible sizes that are set up in at least one currency
    const sizes = new Set()
    for (const priceData of Object.values(currencyData)) {
      for (const size in priceData) {
        sizes.add(size)
      }
    }

    // Generate plans in settings
    for (const size of sizes) {
      Settings.plans.push({
        planCode: `group_${planCode}_${size}_${usage}`,
        name: `${Settings.appName} ${capitalize(
          planCode
        )} - Group Account (${size} licenses) - ${capitalize(usage)}`,
        hideFromUsers: true,
        price: groups[usage][planCode].USD[size],
        annual: true,
        features: Settings.features[planCode],
        groupPlan: true,
        membersLimit: parseInt(size),
        membersLimitAddOn: 'additional-license',
      })
    }
  }
}

module.exports = groups

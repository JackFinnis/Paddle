# import json
# import geopy.distance

# with open('Weirs.json', 'r') as f:
#     locks = json.load(f)

# for lock in locks:
#     lock['id'] = 'id'+lock['id']

# with open('Weirs2.json', 'w') as f:
#     json.dump(locks, f)

import json

with open('Weirs.json', 'r') as f:
    canals = json.load(f)

print(1719 + 1042)
import json

def write(fn, fo):    
    with open(fn, "r") as f:
        x =f.read()
        z = json.loads(x)["abi"]
        zd = {"abi": z}

        with open(fo, "w") as o:
            o.write(json.dumps(zd))


fn = "./build/contracts/FairLaunchPool.json"
fo = "FairLaunchPool.json"
write(fn, fo)

fn = "./build/contracts/NRT.json"
fo = "NRT.json"
write(fn, fo)


# fn = "./artifacts/contracts/NRT.sol/NRT.json"

# with open(fn, "r") as f:
#     x =f.read()
#     z = json.loads(x)["abi"]

#     with open("NRT.abi", "w") as o:
#         o.write(json.dumps(z))        
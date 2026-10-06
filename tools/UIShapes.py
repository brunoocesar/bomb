"""Code-authored oval silhouette, independent of sprite texture pixels."""
from math import sqrt

def oval_children(color, z, transparency=.65, count=32):
    result = []
    for i in range(count):
        y = (i+.5)/count
        width = sqrt(1-(2*y-1)**2)
        result.append({"Name": f"Oval_{i:02}", "ClassName": "Frame", "Properties": {
            "Position": {"UDim2": [[(1-width)/2,0],[i/count,0]]},
            "Size": {"UDim2": [[width,0],[1/count,0]]},
            "BackgroundColor3": color, "BackgroundTransparency": transparency,
            "BorderSizePixel": 0, "ZIndex": z}, "Children": []})
    return result

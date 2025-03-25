import requests
import json

def get_instance_metadata():
    metadata_url = "http://169.254.169.254/latest/meta-data"
    response = requests.get(metadata_url)

    if key:
        key_url = metadata_url + key
        response = response.get(key_url)
        if response.status_code == 200:
            return {key: response.text}
        else:
            return {"error:" f"Failed to retrieve matadate for key: {key}"}

    response = requests.get(metadata_url)
    if response.status_code != 200:
        return {"error:" " Failed to retrieve metadata"}
    
    metadata_keys = response.text.split('\n')
    metadata = {}

    for key in metadata_keys:
        try:
            key_url = metadata_url + key
            key_response = requests.get(key_url)
            if key_response.status_code == 200:
                metadata[key] = key_response.text
        except requests.RequestException:
            metadata[key] = "Unavailable"

    return metadata

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Retrieve AWS instance metadata")
    parser.add_argument("-k", "--key", help="Specify a metadat to reterive individually", required=False)
    args = parser.parse_args()

    instance_metadata = get_instance_metadata()
    print(json.dumps(instance_metadata, indent=4))

if __name__ == "__main__":
    main()
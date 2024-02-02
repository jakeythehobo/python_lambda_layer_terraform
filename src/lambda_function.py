import rdklib
import json


def main(event, context):
    print(rdklib.errors.InvalidParametersError)
    return json.dumps({'message': 'Hello, world!'})


if __name__ == '__main__':
    main()

# Sample code to show how to cache SSM parametes gets with Javascript

The caching function is implemented in the [main.js](index.mjs#L3).

## Deploy

* ```terraform init```
* ```terraform apply```

## Use

To see the initial value (```test value```):

```aws lambda invoke --function-name $(terraform output -raw function) >(jq '.Parameter.Value') > /dev/null```

Modify the parameter:

```aws ssm put-parameter --overwrite --name test-secret --value "new value"```

Get the value a few times until the result changes (<30 sec):

```aws lambda invoke --function-name $(terraform output -raw function) >(jq '.Parameter.Value') > /dev/null```

## Cleanup

* ```terraform destroy```

import json
import boto3
import os

client = boto3.resource('dynamodb')
tableName = os.environ['TABLE_NAME']
table = client.Table(tableName)


def lambda_handler(event, context):
  
    table.update_item(
    Key={
        'crcItem': 'resumePage',
    },
    UpdateExpression='SET visit_count = visit_count + :val1',
    ExpressionAttributeValues={
        ':val1': 1
    }
    )
    response = table.get_item(
      Key = {
        'crcItem' : 'resumePage'
      }
    )

    data = {
        'statusCode': 200,
        'body': response.get('Item'),
        'headers': {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
    }
  
    return data
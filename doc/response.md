# Response

The response object represents a HTTP response. It gives us the tools we need to render a proper rack compatible response.

The response object has two kind of methods, `helpers` and `finishers`. Helpers builds the response and finishers stops execution of the action and sends the response to the client.

## Helpers

All helper methods returns `self` when setitng a value to enable method chaining: `res.status(201).type(:text).write('Resource Created')`.

#### `content_type` `type`
#### `header`
#### `body`
#### `status`

## Finishers

#### `write`
#### `head`
#### `redirect`
#### `json`

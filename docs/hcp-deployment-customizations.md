# HCP Deployment Customizations

On this page are various deployment HCP-specific customizations and their corresponding input variables that you may set to meet your requirements.

## HCP Boundary

The Workers created with this module can be used with HCP Boundary. Please review the `hcp` example. Please review this documentation to retrieve the `Worker Auth Registration Request` needed for HCP Boundary. <https://developer.hashicorp.com/hcp/docs/boundary/self-managed-workers/install-self-managed-workers#start-the-self-managed-worker>

If using controller-led worker authorization, follow [these instructions](https://developer.hashicorp.com/boundary/docs/workers/registration#controller-led-authorization) to use the Boundary CLI (UI not currently supported) to get the Boundary controller PKI token from the HCP server.  Make sure to set the `controller_generated_activation_token` variable to the value returned by the CLI.

If using worker-led worker authorization [details here](https://developer.hashicorp.com/boundary/docs/workers/registration#worker-led-authorization), leave the `controller_generated_activation_token` variable empty and then make sure to set the registration.

>📝 Note: kms-led worker authorization is not currently supported for HCP Boundary


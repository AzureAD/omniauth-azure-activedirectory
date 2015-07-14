module OmniAuth
  # Constants relevant to AzureAD.
  module AzureAD
    # Valid parameters in the decoded JWT claim.
    module JWTClaim
      ISSUER = 'iss'
      SUBJECT = 'sub'
      AUDIENCE = 'aid'
      EXPIRATION_TIME = 'exp'
      NOT_BEFORE = 'nbf'
      ISSUED_AT = 'iat'
      JWT_ID = 'jti'
    end

    # Valid parameters in the decoded JOSE header.
    module JOSEHeader
      TYPE = 'typ'
      CONTENT_TYPE = 'cty'
      ALGORITHM = 'alg'
    end
  end
end

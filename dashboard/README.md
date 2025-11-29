# Dashboard Files

Place your HTML, CSS, and JavaScript files here:

- `index.html` - Main dashboard page
- `styles.css` - Dashboard styles
- `scripts.js` - Dashboard JavaScript

These files will be automatically uploaded to S3 by Terraform.

## File Structure

```
dashboard/
├── index.html
├── styles.css
└── scripts.js
```

## S3 Structure

After deployment, your S3 bucket will have:

```
s3://your-bucket/
├── dashboard/
│   ├── index.html
│   ├── styles.css
│   └── scripts.js
└── reports/
    ├── daily/
    │   └── daily.json (created by Lambda)
    └── weekly/
        └── YYYY-Www.csv (created by Lambda)
```

## Accessing Your Dashboard

After deployment, access your dashboard at:
```
http://your-bucket.s3-website-us-west-2.amazonaws.com/dashboard/index.html
```

Or use the CloudFront URL if you set up CloudFront distribution.

Output:
- Print a changelog using this template:

```text
Docker dependency changelog

Updated:
- <dependency>: <old version> -> <new version> (<source>)

Unchanged:
- <dependency>: <version> (<reason>)

Observed but not pinned:
- <dependency>: <observed version> (<reason>)

Notes:
- <short note, or "None">
```

- Omit empty sections except `Notes`.

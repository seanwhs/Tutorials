# Part 3e — Template Method

Defines the **skeleton** of an algorithm in a base class, deferring specific steps to subclasses — the algorithm's structure stays fixed while individual steps vary.

```python
from abc import ABC, abstractmethod

class DataPipeline(ABC):
    """The base class defines the FIXED sequence of steps (the 'template').
    Subclasses only override the steps that actually differ."""

    def run(self) -> None:
        # This method is the template -- its order is never overridden by subclasses
        data = self.extract()
        cleaned = self.transform(data)
        self.load(cleaned)
        self.notify_completion()

    @abstractmethod
    def extract(self) -> list: ...

    @abstractmethod
    def transform(self, data: list) -> list: ...

    @abstractmethod
    def load(self, data: list) -> None: ...

    def notify_completion(self) -> None:
        # A "hook" with a default implementation -- subclasses MAY override it, but don't have to
        print("Pipeline finished successfully.")


class CsvToPostgresPipeline(DataPipeline):
    def extract(self) -> list:
        print("Reading rows from CSV file...")
        return ["row1", "row2", "row3"]

    def transform(self, data: list) -> list:
        print("Uppercasing rows...")
        return [row.upper() for row in data]

    def load(self, data: list) -> None:
        print(f"Inserting into Postgres: {data}")


class ApiToS3Pipeline(DataPipeline):
    def extract(self) -> list:
        print("Fetching records from API...")
        return ["record_a", "record_b"]

    def transform(self, data: list) -> list:
        print("Filtering records...")
        return [r for r in data if "a" in r]

    def load(self, data: list) -> None:
        print(f"Uploading to S3 bucket: {data}")

    def notify_completion(self) -> None:
        # Overriding the optional hook -- e.g. send a Slack message instead of printing
        print("Slack notification sent: pipeline complete!")


# Usage -- both pipelines share the exact same run() sequence, only steps differ
CsvToPostgresPipeline().run()
print("---")
ApiToS3Pipeline().run()
```

**Expected output:**
```
Reading rows from CSV file...
Uppercasing rows...
Inserting into Postgres: ['ROW1', 'ROW2', 'ROW3']
Pipeline finished successfully.
---
Fetching records from API...
Filtering records...
Uploading to S3 bucket: ['record_a']
Slack notification sent: pipeline complete!
```

---


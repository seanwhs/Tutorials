                         Incoming Request
                                │
                     ┌──────────┴───────────┐
                     │      Middleware      │
                     │ (logging, auth, etc)│
                     └──────────┬───────────┘
                                │
                     ┌──────────┴───────────┐
                     │      Decorators      │
                     │ (@cache, @throttle) │
                     └──────────┬───────────┘
                                │
                     ┌──────────┴───────────┐
                     │     CBV Class        │
                     │     dispatch()       │
                     └─────┬─────┬──────────┘
                           │     │
               ┌───────────┘     └─────────────┐
               ▼                                 ▼
          GET Method                           POST Method
               │                                 │
      ┌────────┴────────┐               ┌────────┴────────┐
      │ form_valid()     │               │ form_valid()     │
      │ form_invalid()   │               │ form_invalid()   │
      └────────┬────────┘               └────────┬────────┘
               │                                 │
        get_context_data()                  get_context_data()
               │                                 │
        Template Rendering                   Template Rendering
               │                                 │
        Response Modifications               Response Modifications
               │                                 │
               ▼                                 ▼
          Outgoing Response                   Outgoing Response

CRUDL Map:
 Create -> CreateView -> POST -> form_valid
 Read   -> DetailView -> GET  -> get_queryset
 Update -> UpdateView -> POST -> form_valid
 Delete -> DeleteView -> POST -> success_url
 List   -> ListView   -> GET  -> get_queryset

Observability Layer:
 - Async tasks
 - DB queries
 - Latency metrics
 - Endpoint heatmaps

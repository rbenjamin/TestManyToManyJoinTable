
#Demonstrates a Many-to-Many Join Table#


- Demonstrates `Schema` implementation for `@Model` migrations.
- Demonstrates using thin sendable structs to represent SwiftData entities. 
- Allows many-to-many relationships to be filtered via predicate.
- Supports paging and offset in the main list.
- Demonstrates this support via a search bar that supports filtering via tokens.
- Does not use `@Query` for main list content. This type of implementation would not work for time-sensitive CloudKit projects that depend on synched devices at all times.
    - Hopefully Apple will add support for Observable fetches outside of View body.
- In most cases, I think sticking with `@Query` or with `CoreData` is a better choice than the complexity of this implementation, but I wanted to see whether I could get it working!

##Warning##
- Test validation code extensively.  There might be edge-cases with CloudKit.
- This *should* not be a problem for removal, but if recipes are retrieved by cloudkit before RecipeKeywordIndex values, there could be duplicates created for those indices.

##How-To##
- To use, configure with your CloudKit settings, or setup to use a basic local SwiftData sqlite db.  Once configured for your app, check DataProvider.swift to ensure the ModelContainer knows the right location for the database.
- Does not support paging in the keywords list -- recipes represents the more expensive object, even though *this* example doesn't actually have costly recipe entities.
- Regularly validates join tables to ensure they don't go out-of-sync.
- RecipeKeywordIndex does not maintain real relationships for performance reasons (uses a UUID) -- to ensure the joins are deleted when the recipes are deleted, use DataHandler to delete all objects, especially those that require a join-table.
- Use a custom migration when implementing a join table to do the initial setup.


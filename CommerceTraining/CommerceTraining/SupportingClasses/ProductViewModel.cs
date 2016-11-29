using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace CommerceTraining.SupportingClasses
{
    public class ProductViewModel
    {
        public ProductContent CurrentContent { get; set; }

        public IEnumerable<ContentReference> VariantLinks { get; set; }

        public NameAndUrls SelectedVariant { get; set; }

        public IEnumerable<SelectListItem> Sizes { get; set; }

        public IEnumerable<SelectListItem> Colors { get; set; }
    }
}
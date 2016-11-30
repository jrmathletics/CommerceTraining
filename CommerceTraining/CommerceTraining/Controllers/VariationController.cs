using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web.Mvc;
using CommerceTraining.Models.Catalog;
using CommerceTraining.Models.ViewModels;
using EPiServer;
using EPiServer.Commerce.Catalog;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using EPiServer.Web.Routing;
using Mediachase.Commerce;

namespace CommerceTraining.Controllers
{
    public class VariationController : MyControllerBase<ShirtVariation>
    {
        public ActionResult Index(ShirtVariation currentContent)
        {
            /* Implementation of action. You can create your own view model class that you pass to the view or
             * you can pass the page type for simpler templates */
            var viewModel = new ShirtVariationViewModel();

            if(currentContent.MainBody!=null)
            { 
               viewModel.MainBody = currentContent.MainBody.ToString();
            }
            viewModel.priceString = currentContent.GetDefaultPrice().UnitPrice.Amount.ToString(CultureInfo.CurrentCulture);
            if (GetDefaultAsset(currentContent) != null)
            { 
                viewModel.image = GetDefaultAsset(currentContent);
            }
            viewModel.CanBeMonogrammed = currentContent.CanBeMonogrammed;


            return View(viewModel);
        }

        public VariationController(IContentLoader contentLoader, UrlResolver urlResolver, AssetUrlResolver assetUrlResolver, ThumbnailUrlResolver thumbnailUrlResolver) : base(contentLoader, urlResolver, assetUrlResolver, thumbnailUrlResolver)
        {
        }
    }
}